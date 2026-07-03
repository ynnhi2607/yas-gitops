#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
case "$ENVIRONMENT" in
  dev|staging)
    kubectl apply -f "environments/${ENVIRONMENT}/argocd-apps.yaml"
    ;;
  *)
    echo "Usage: $0 [dev|staging]" >&2
    exit 1
    ;;
esac

echo "Applied ArgoCD apps for ${ENVIRONMENT}."
echo "kubectl get applicationsets -n argocd"
echo "kubectl get applications -n argocd | grep yas-${ENVIRONMENT}"
