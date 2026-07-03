# YAS GitOps

GitOps repository for the YAS DevOps project.

This repo is intentionally separate from the application source repo `yas`:

- `yas`: application source code, Jenkins CI, Docker image build/push.
- `yas-gitops`: Kubernetes desired state for ArgoCD.

## Environments

- `yas-dev`: tracks normal development images, default tag `main`.
- `yas-staging`: tracks release images, default tag `v1.0.0`.

Only the demo core services are managed here:

```text
product, cart, order, customer, inventory, tax, media, search,
storefront-bff, storefront-ui, backoffice-bff, backoffice-ui,
swagger-ui, sampledata
```

Disabled services such as payment, promotion, rating, recommendation, webhook,
and location are intentionally excluded to keep the local Minikube demo stable.

## Install ArgoCD

```bash
./scripts/install-argocd.sh
```

Open UI:

```bash
kubectl port-forward svc/argocd-server -n argocd 8081:443
```

Get initial password:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode
```

Login at `https://localhost:8081` with user `admin`.

## Deploy Dev

```bash
./scripts/apply-apps.sh dev
kubectl get applications -n argocd | grep yas-dev
kubectl get pods -n yas-dev
```

Dev URLs use separate hosts from the basic Jenkins demo:

```text
http://storefront-dev.yas.local.com:31788
http://backoffice-dev.yas.local.com:31788
http://api-dev.yas.local.com:31788/swagger-ui/
```

## Deploy Staging

Before syncing staging, make sure the matching release images exist in Docker Hub,
for example `ynnhi2607/yas-tax:v1.0.0`.

```bash
./scripts/apply-apps.sh staging
kubectl get applications -n argocd | grep yas-staging
kubectl get pods -n yas-staging
```

Staging URLs:

```text
http://storefront-staging.yas.local.com:31788
http://backoffice-staging.yas.local.com:31788
http://api-staging.yas.local.com:31788/swagger-ui/
```

## Updating Image Tags

Jenkins updates files under `environments/<env>/services/*.yaml` after building
and pushing images. ArgoCD detects the Git change and syncs Kubernetes.

Example dev image update:

```yaml
backend:
  image:
    repository: ynnhi2607/yas-tax
    tag: ddaa8b60
```
