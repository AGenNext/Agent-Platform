# EnterpriseApp Platform Contract

EnterpriseApp is the AGenNext deployment contract for enterprise applications on Kubernetes.

The first goal is intentionally small:

```text
EnterpriseApp
  -> Deployment
  -> Service
  -> PVC
  -> Ingress
```

Liferay is included as a catalog entry, but it should not be the first validation target. Start with `whoami`, then promote to Liferay after the reconciliation loop is stable.

## Files

```text
platform/enterprise-app/
├── crd/enterpriseapps.platform.agennext.io.yaml
├── catalog/whoami.yaml
├── catalog/liferay.yaml
├── kpack/liferay-image.yaml
└── README.md
```

## Apply the CRD

```bash
kubectl apply -f platform/enterprise-app/crd/enterpriseapps.platform.agennext.io.yaml
```

## Apply the golden sample

```bash
kubectl create namespace platform-apps --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f platform/enterprise-app/catalog/whoami.yaml
```

## Liferay contract

```bash
kubectl create namespace liferay --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f platform/enterprise-app/catalog/liferay.yaml
```

## Buildpack path

The `kpack/liferay-image.yaml` file defines the intended cluster-native image build path:

```text
Git source -> kpack Image -> OCI image -> EnterpriseApp deployment
```

The operator/reconciler should later convert EnterpriseApp intent into native Kubernetes resources.
