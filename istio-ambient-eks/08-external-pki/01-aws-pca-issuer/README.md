# cert-manager and aws-privateca-issuer

Common to every pattern. Assumes the PCA subordinate CA from `../README.md`
exists and is `ACTIVE`:

```sh
export CLUSTER=ambient-kgateway
export AWS_REGION=us-west-2
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export SUB_CA_ARN=arn:aws:acm-pca:$AWS_REGION:$ACCOUNT_ID:certificate-authority/<id>
```

## 1. cert-manager

```sh
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade -i cert-manager jetstack/cert-manager -n cert-manager --create-namespace \
  --version v1.21.3 --set crds.enabled=true --wait
```

`cert-manager` is not enrolled in ambient and does not need to be.

## 2. IAM for the issuer (IRSA)

`iam-policy.json` grants the three calls the issuer makes —
`DescribeCertificateAuthority`, `IssueCertificate`, `GetCertificate` — on the
one subordinate CA. Edit the ARN, then:

```sh
aws iam create-policy --policy-name $CLUSTER-pca-issuer \
  --policy-document file://iam-policy.json

eksctl create iamserviceaccount --cluster $CLUSTER \
  --namespace cert-manager --name aws-privateca-issuer \
  --attach-policy-arn arn:aws:iam::$ACCOUNT_ID:policy/$CLUSTER-pca-issuer \
  --approve
```

(Or add the same entry under `iam.serviceAccounts` in
`../../01-eks-cluster/cluster.yaml`.) For a CA in another account, add
`spec.role` to the issuer with a role there that trusts this one.

## 3. aws-privateca-issuer

```sh
helm repo add awspca https://cert-manager.github.io/aws-privateca-issuer
helm upgrade -i aws-privateca-issuer awspca/aws-privateca-issuer -n cert-manager \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-privateca-issuer --wait
```

Pin `--version` to the current chart release in production.

## 4. The issuer

```sh
envsubst < awspcaclusterissuer.yaml | kubectl apply -f -
kubectl get awspcaclusterissuer aws-pca -o jsonpath='{.status.conditions}'   # Ready=True
```

Two settings on the issuer worth knowing:

- **No `pcaTemplate.defaultTemplateName`.** A default template overrides the
  issuer's own choice, including the `SubordinateCACertificate_PathLen0/V1` it
  uses for `isCA: true` certificates — Patterns 1 and 2 would then get leaf
  certificates instead of an intermediate.
- **`notBeforeOffset`.** PCA backdates `NotBefore` by an hour by default, which
  makes short-lived certificates look older than they are and triggers early
  renewal. The issuer (v1.10+) defaults to 15 minutes; set it explicitly for
  Pattern 3.

## Files

- `iam-policy.json` — least-privilege policy for one CA
- `awspcaclusterissuer.yaml` — the `AWSPCAClusterIssuer` named `aws-pca`

Docs:

- <https://github.com/cert-manager/aws-privateca-issuer>
- <https://cert-manager.io/docs/installation/helm/>
