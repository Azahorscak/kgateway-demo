# istio-csr — Patterns 2 and 3

## What istio-csr is

[istio-csr](https://cert-manager.io/docs/usage/istio-csr/) is a cert-manager
project that implements Istio's certificate-signing gRPC API (the one istiod
normally serves on 15012). Istio clients — ztunnel, waypoints, sidecars — send
their CSRs to it instead of istiod. For each CSR it:

1. authenticates the caller with its Kubernetes service account token
   (TokenReview), and checks the requested SPIFFE identity matches it — or, for
   accounts listed in `caTrustedNodeAccounts`, that the caller may act for it;
2. creates a cert-manager `CertificateRequest` against the configured issuer;
3. waits for it to be approved and signed, and returns the chain.

It also creates istiod's own serving certificate (`istiod-tls`) and writes the
trust anchor into the `istio-ca-root-cert` ConfigMap in every namespace.

With istio-csr, istiod runs with `ENABLE_CA_SERVER=false`: it is only a config
server and holds no CA key. Whatever issuer cert-manager can talk to becomes
the mesh CA — here, AWS PCA, either through a local intermediate or directly.

```
            ztunnel / waypoint ── CSR (gRPC, :443) ──▶ istio-csr  (cert-manager ns)
                    ▲                                     │ CertificateRequest
                    │ xDS (:15012)                        ▼
                  istiod (CA off)          Pattern 2: Issuer istio-ca (CA, key from PCA)
                                           Pattern 3: AWSPCAClusterIssuer ──▶ AWS PCA
```

### Why use it

- **Separation of duties** — the component exposed to every proxy (istiod) no
  longer has a signing key.
- **One certificate policy surface** — workload certs are cert-manager
  `CertificateRequest`s, so cert-manager's
  [approver-policy](https://cert-manager.io/docs/policy/approval/approver-policy/)
  can constrain them (allowed SPIFFE URIs, durations, key types) the same way
  it constrains every other certificate in the cluster.
- **Any issuer** — swap the issuer reference to move between a local CA, AWS
  PCA, Vault, Venafi, etc. without touching Istio.
- **Pattern 3 becomes possible** — istiod has no way to forward signing to
  PCA; istio-csr does.

### What it costs

- Another component on the critical path of pod start-up. Run at least two
  replicas (`replicaCount`) and a PDB; if istio-csr is down, no new identities
  are issued.
- Install order matters: istio-csr before istiod (istiod waits for
  `istiod-tls`), and changing the CA of a running mesh needs a root migration.

## Install

Prerequisites: `../01-aws-pca-issuer/` done, Istio not yet installed.

```sh
export ISTIO_CSR_VERSION=v0.18.0
```

### 1. The issuer chain

Pattern 2 — local intermediate signed by PCA:

```sh
kubectl apply -f intermediate.yaml
kubectl wait -n istio-system certificate/istio-ca --for=condition=Ready
```

Pattern 3 — a short-lived-mode PCA subordinate and its issuer:

```sh
export SHORT_LIVED_CA_ARN=arn:aws:acm-pca:...   # created with --usage-mode SHORT_LIVED_CERTIFICATE
kubectl create namespace istio-system
envsubst < awspcaclusterissuer-short-lived.yaml | kubectl apply -f -
```

Add that CA's ARN to the IAM policy from `../01-aws-pca-issuer/`.

### 2. Pin the root

Give istio-csr the root certificate out-of-band rather than trusting what the
issuer returns:

```sh
# Root in AWS PCA:
aws acm-pca get-certificate-authority-certificate \
  --certificate-authority-arn $ROOT_CA_ARN --query Certificate --output text > ca.pem
# Offline root: use the root PEM from your PKI team.

kubectl create secret generic istio-root-ca -n cert-manager --from-file=ca.pem
```

### 3. istio-csr

```sh
# Pattern 2
helm upgrade -i cert-manager-istio-csr jetstack/cert-manager-istio-csr -n cert-manager \
  --version $ISTIO_CSR_VERSION -f istio-csr-values.yaml --wait

# Pattern 3
helm upgrade -i cert-manager-istio-csr jetstack/cert-manager-istio-csr -n cert-manager \
  --version $ISTIO_CSR_VERSION -f istio-csr-values.yaml -f istio-csr-values-pca-direct.yaml --wait

kubectl get secret -n istio-system istiod-tls        # created by istio-csr
kubectl get cm -n istio-system istio-ca-root-cert    # the pinned root
```

### 4. Istio with the overlays

Same four installs as `../../02-istio-ambient/`, with two extra `-f` flags:

```sh
cd ../../02-istio-ambient
O=../08-external-pki/03-istio-csr

helm upgrade -i istio-base istio/base -n istio-system --version $ISTIO_VERSION --wait
helm upgrade -i istiod istio/istiod -n istio-system --version $ISTIO_VERSION \
  -f istiod-values.yaml -f $O/istiod-values.yaml --wait
helm upgrade -i istio-cni istio/cni -n istio-system --version $ISTIO_VERSION \
  -f cni-values.yaml --wait
helm upgrade -i ztunnel istio/ztunnel -n istio-system --version $ISTIO_VERSION \
  -f ztunnel-values.yaml -f $O/ztunnel-values.yaml --wait
```

Then carry on with `03-kgateway/` onward; nothing there changes.

## Check

```sh
# one CSR per identity per node; errors here usually mean approval or IAM
kubectl logs -n cert-manager deploy/cert-manager-istio-csr --tail=50

# chain on ztunnel
istioctl ztunnel-config certificate --node <a node running httpbin>

# Pattern 3: PCA-side
aws acm-pca create-certificate-authority-audit-report \
  --certificate-authority-arn $SHORT_LIVED_CA_ARN \
  --s3-bucket-name <bucket> --audit-report-response-format JSON
```

Set `app.certmanager.preserveCertificateRequests: true` while debugging to
keep the `CertificateRequest`s around in `istio-system`.

## Ambient notes

- **`caTrustedNodeAccounts: istio-system/ztunnel` is required.** ztunnel
  authenticates as itself and asks for the identity of each pod on its node.
  Without the flag istio-csr rejects every one of those CSRs and enrolled pods
  have no mTLS identity.
- **ztunnel has its own `caAddress`.** The istiod chart's `global.caAddress`
  covers injected proxies (waypoints) but not the ztunnel DaemonSet.
- **Certificate counts scale with nodes, not just pods.** An identity is held
  by every ztunnel that has a pod with that service account. A Deployment
  spread over 10 nodes is 10 certificates per renewal — relevant for Pattern 3
  billing and quotas.
- **kgateway** is untouched: its identity lives in ztunnel.

## Hardening

- **Approval.** cert-manager's built-in approver approves every
  `CertificateRequest`. For a mesh CA, install cert-manager with
  `--set disableAutoApproval=true` and deploy approver-policy with a
  `CertificateRequestPolicy` that only allows istio-csr's service account to
  request `spiffe://cluster.local/ns/*/sa/*` URIs with no DNS names and a
  bounded duration. Every other certificate (the `istio-ca` intermediate,
  `istiod-tls`) then needs a policy of its own too.
- **RBAC.** In Pattern 2 the `istio-system/istio-ca` Secret is the signing
  key; only cert-manager needs to read it. Enable EKS Secrets encryption with
  KMS.
- **Pattern 3 limits.** Check the account's `IssueCertificate` and
  `GetCertificate` rate quotas against (identities × nodes) / renewal interval,
  with headroom for a mass restart (node replacement, ztunnel upgrade) where
  everything renews at once.

Docs:

- <https://cert-manager.io/docs/usage/istio-csr/>
- <https://cert-manager.io/docs/usage/istio-csr/installation/>
- <https://github.com/cert-manager/istio-csr>
- <https://docs.aws.amazon.com/privateca/latest/userguide/short-lived-certificates.html>
