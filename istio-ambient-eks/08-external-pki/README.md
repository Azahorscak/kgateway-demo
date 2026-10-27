# Mesh PKI with AWS Private CA, root of trust outside the cluster

By default istiod generates a self-signed root on first start and keeps its key
in the `istio-ca-secret` Secret. That is fine for a demo and wrong for most
production meshes: the root key lives in etcd, nothing outside the cluster
trusts it, and two clusters never share it.

This section replaces that root with one that lives **outside the cluster**,
with [AWS Private CA](https://docs.aws.amazon.com/privateca/latest/userguide/PcaWelcome.html)
(PCA) as the online issuing CA and cert-manager's
[aws-privateca-issuer](https://github.com/cert-manager/aws-privateca-issuer)
as the bridge into Kubernetes. The cluster only ever holds the root
*certificate* (public), never the root key.

| Directory | Covers |
|--|--|
| `01-aws-pca-issuer/` | cert-manager, aws-privateca-issuer, IAM, and the `AWSPCAClusterIssuer` every pattern below uses |
| `02-plugin-ca/` | Pattern 1 — PCA issues istiod an intermediate (`cacerts`); istiod keeps signing workloads |
| `03-istio-csr/` | Patterns 2 and 3 — istiod's CA is switched off and cert-manager signs workload certificates via istio-csr |

> **Do this at install time.** The PKI choice belongs in step 3 of the
> top-level order of operations (before istiod first starts). Changing the
> root of an existing mesh breaks mTLS between pods holding old and new
> certificates — see [Migrating an existing mesh](#migrating-an-existing-mesh).

## The trust chain

```
  ┌────────────────────────────┐
  │ Root CA                    │  outside the cluster: AWS PCA root (ideally in a
  │                            │  separate security account) or an offline/on-prem
  └─────────────┬──────────────┘  root (HSM, Vault, corporate PKI)
                │ signs (pathLen ≥ 1)
  ┌─────────────▼──────────────┐
  │ AWS PCA subordinate CA     │  online, per environment or per region;
  │                            │  key never leaves PCA's HSMs
  └─────────────┬──────────────┘
                │  IssueCertificate  (aws-privateca-issuer, IRSA)
  ┌─────────────▼──────────────┐
  │ cluster intermediate       │  Pattern 1: istiod's `cacerts`
  │   (pathLen 0)              │  Pattern 2: cert-manager CA Issuer behind istio-csr
  └─────────────┬──────────────┘  Pattern 3: (none — PCA signs workloads directly)
                │
  ┌─────────────▼──────────────┐
  │ workload certs             │  spiffe://cluster.local/ns/<ns>/sa/<sa>
  │                            │  held by ztunnel (and waypoints) on the workload's behalf
  └────────────────────────────┘
```

### Where the root lives

Two layouts are common; both look the same from inside the cluster.

**Root in AWS PCA.** A `ROOT` CA in a locked-down security account issues
`SUBORDINATE` CAs (one per environment/region). The subordinate is shared to
the workload account with AWS RAM, or the issuer assumes a role in the
security account (`spec.role` on the issuer). The root is used only to sign
subordinates — consider disabling it between uses.

**Root outside AWS.** An offline root (HSM, Vault, an existing enterprise PKI)
signs the CSR of a PCA subordinate, which is then imported:

```sh
aws acm-pca create-certificate-authority \
  --certificate-authority-type SUBORDINATE \
  --certificate-authority-configuration file://sub-ca-config.json   # KeyAlgorithm, SigningAlgorithm, Subject

aws acm-pca get-certificate-authority-csr \
  --certificate-authority-arn $SUB_CA_ARN --output text > sub-ca.csr

# Sign sub-ca.csr with the offline root. It MUST allow pathLen >= 1 — see below.

aws acm-pca import-certificate-authority-certificate \
  --certificate-authority-arn $SUB_CA_ARN \
  --certificate fileb://sub-ca.pem \
  --certificate-chain fileb://root.pem
```

When the root is in PCA instead, issue the subordinate with the
`arn:aws:acm-pca:::template/SubordinateCACertificate_PathLen1/V1` template.

**PathLen matters.** In Patterns 1 and 2 the cluster holds its own CA, so the
chain is root → PCA subordinate → cluster intermediate → workload. The PCA
subordinate therefore needs `pathLen >= 1`. aws-privateca-issuer issues any
`isCA: true` certificate with `SubordinateCACertificate_PathLen0/V1`, so the
cluster intermediate gets `pathLen 0` (it can sign workloads, nothing else) —
which is what you want.

## The patterns

| | 1. Plug-in CA | 2. istio-csr + local CA | 3. istio-csr → PCA direct |
|--|--|--|--|
| Who signs workload certs | istiod | cert-manager `CA` Issuer | AWS PCA |
| Signing key in the cluster | yes — `istio-system/cacerts` | yes — `istio-system/istio-ca` (not readable by istiod) | **no** |
| PCA calls | one per intermediate rotation | one per intermediate rotation | one per workload cert rotation |
| istiod CA server | on | off | off |
| Extra components | cert-manager, aws-privateca-issuer | + istio-csr | + istio-csr |
| PCA outage | none until the intermediate expires | none until the intermediate expires | new pods get no identity; running pods fail at cert expiry |
| Audit trail per workload cert | istiod logs | `CertificateRequest`s (optional) | CloudTrail + PCA audit report |
| Directory | `02-plugin-ca/` | `03-istio-csr/` | `03-istio-csr/` |

**Pattern 1 — plug-in CA.** The smallest change to stock Istio. cert-manager
keeps an intermediate in the `cacerts` Secret fresh, and istiod (1.27)
hot-reloads it as long as the root does not change. Pick this unless you have a
reason not to.

**Pattern 2 — istio-csr with a cluster-local intermediate.** istiod no longer
holds a signing key and no longer runs a CA; istio-csr answers Istio's CSR
gRPC API and turns each request into a cert-manager `CertificateRequest`
against a `CA` Issuer whose key PCA issued. Pick this when policy says the
control plane must not hold CA keys, or when you want issuance to go through
cert-manager (approver-policy, one place for all certificate policy).

**Pattern 3 — istio-csr straight to PCA.** Every workload certificate is
signed by PCA; no CA key exists in the cluster at all. This is the strongest
"root of trust outside the cluster" story, and the most expensive one: PCA
bills per certificate, every ztunnel-held identity renews several times a day,
the `IssueCertificate` API has per-account rate quotas, and pod start-up
depends on a regional AWS API. If you go this way, use a separate PCA
subordinate in `SHORT_LIVED_CERTIFICATE` usage mode (validity ≤ 7 days,
cheaper per certificate) and raise istio-csr's maximum certificate duration —
see `03-istio-csr/`.

**Multi-cluster — any of the above, once per cluster.** Every cluster gets its
own intermediate (Patterns 1/2) or its own issuer (Pattern 3) under the same
root. Workloads in different clusters then trust each other's certificates
without sharing any key, which is the prerequisite for Istio multi-cluster and
multi-network. Keep the same trust domain or configure `trustDomainAliases`.

## Ambient specifics

- **ztunnel requests certificates for other identities.** One ztunnel per node
  asks for a certificate for each enrolled pod's service account on that node.
  istiod's own CA allows this out of the box; istio-csr has to be told
  (`app.server.caTrustedNodeAccounts: istio-system/ztunnel`) and ztunnel has
  to be pointed at it (`caAddress`).
- **kgateway needs nothing.** The kgateway proxy has no Istio agent; ztunnel
  holds the `cluster.local/ns/kgateway-system/sa/http` identity for it. The
  `AuthorizationPolicy` in `06-mesh-security/` keeps working unchanged.
- **Waypoints** are Istio proxies; they get their CA address from
  `global.caAddress` in the istiod values, same as everything istiod injects.

## North-south certificates from the same PCA

The `AWSPCAClusterIssuer` from `01-aws-pca-issuer/` can also issue the
kgateway listener certificate for internal-facing gateways: a cert-manager
`Certificate` with `issuerRef` pointing at it, and the resulting Secret
referenced from the `Gateway` listener exactly as in
`oss/02-listeners/https-termination/`. Clients must trust the private root, so
this suits internal / private-NLB gateways, not public ones.

## Migrating an existing mesh

Workloads only trust the root they were given. To move a running mesh from
istiod's self-signed root to the PCA root without dropping connections:

1. Distribute a trust bundle holding **both** roots (meshConfig
   `caCertificates`, or for istio-csr, the `rootCAFile` with both PEMs).
   Check which of these ztunnel honours in the Istio version you run before
   relying on it.
2. Restart ztunnel and waypoints so they pick the bundle up.
3. Switch issuance (install `cacerts` and restart istiod, or switch to
   istio-csr), then restart ztunnel again so every identity is re-issued.
4. Once nothing holds an old-root certificate, drop the old root from the
   bundle.

On a demo cluster it is simpler to tear down and reinstall Istio.

Docs:

- <https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/>
- <https://cert-manager.io/docs/usage/istio-csr/>
- <https://github.com/cert-manager/aws-privateca-issuer>
- <https://docs.aws.amazon.com/privateca/latest/userguide/ca-hierarchy.html>
- <https://docs.aws.amazon.com/privateca/latest/userguide/short-lived-certificates.html>
