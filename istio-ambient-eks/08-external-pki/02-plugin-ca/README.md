# Pattern 1 — plug-in CA from AWS PCA

istiod keeps its CA, but instead of self-signing a root it signs workloads
with an intermediate that PCA issued. cert-manager owns that intermediate and
renews it.

```
PCA subordinate ──IssueCertificate──▶ cert-manager ──▶ Secret istio-system/cacerts
                                                              │ mounted at /etc/cacerts
                                                         istiod (CA on)
                                                              │ signs
                                                       ztunnel / waypoints
```

## Install

After `../01-aws-pca-issuer/`, and **before** the istiod Helm install in
`../../02-istio-ambient/`:

```sh
kubectl apply -f certificate-cacerts.yaml
kubectl wait -n istio-system certificate/cacerts --for=condition=Ready

# Then continue with 02-istio-ambient/ as written — istiod-values.yaml needs
# no change. istiod finds /etc/cacerts/tls.crt and logs:
#   "Using kubernetes.io/tls secret type for signing ca files"
#   "Use local CA certificate"
kubectl logs -n istio-system deploy/istiod | grep -i 'ca certificate\|signing ca'
```

## Check

Once the apps from `04-sample-apps/` are running:

```sh
istioctl ztunnel-config certificate --node <a node running httpbin>
# chain: workload cert → ambient-kgateway istiod intermediate → PCA subordinate → root
```

`ca.crt` in the Secret is the root that PCA returned; it becomes the mesh's
trust anchor (`istio-ca-root-cert` ConfigMap in every namespace).

## Rotation

- **Intermediate renewal** — cert-manager re-issues the Secret at
  `renewBefore`. istiod (1.27) watches `/etc/cacerts` and swaps in the new key
  without a restart, provided the root is unchanged. Workload certs signed by
  the old intermediate stay valid until they expire (24h by default).
- **Root change** — not automatic; see "Migrating an existing mesh" in
  `../README.md`.

## Trade-offs

- The intermediate's private key sits in a Secret in `istio-system`. Anyone
  who can read Secrets there can mint mesh identities until the intermediate
  expires — lock down RBAC, enable EKS envelope encryption with KMS, and keep
  `duration` short.
- istiod keeps working through a PCA outage until the intermediate expires.

Docs:

- <https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/>
- <https://cert-manager.io/docs/usage/certificate/>
