#!/usr/bin/env bash
set -euo pipefail

plan_file="${1:-developer-build-plan.tsv}"
target_env="${TARGET_ENV:-dev}"
default_ingress_address="${DEFAULT_INGRESS_ADDRESS:-34.143.145.109}"

if [[ ! -f "$plan_file" ]]; then
  echo "Plan file not found: $plan_file" >&2
  exit 1
fi

ingress_address="${INGRESS_ADDRESS:-}"
if [[ -z "$ingress_address" ]] && command -v kubectl >/dev/null 2>&1; then
  ingress_address="$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
fi
ingress_address="${ingress_address:-$default_ingress_address}"

echo ""
echo "Hosts entries:"
echo "  ${ingress_address} storefront-dev.yas.local.com"
echo "  ${ingress_address} backoffice-dev.yas.local.com"
echo "  ${ingress_address} api-dev.yas.local.com"
echo "  ${ingress_address} storefront-staging.yas.local.com"
echo "  ${ingress_address} backoffice-staging.yas.local.com"
echo "  ${ingress_address} api-staging.yas.local.com"
echo "  ${ingress_address} identity.yas.local.com"
echo ""
echo "Main URLs:"
echo "  Storefront: http://storefront-${target_env}.yas.local.com"
echo "  Backoffice: http://backoffice-${target_env}.yas.local.com"
echo "  Swagger UI: http://api-${target_env}.yas.local.com/swagger-ui/"
echo ""
echo "Developer build plan:"
printf "  %-18s %-28s %-36s %-12s\n" "SERVICE" "BRANCH" "IMAGE" "NODEPORT"
printf "  %-18s %-28s %-36s %-12s\n" "-------" "------" "-----" "--------"

while IFS=$'\t' read -r service_name branch repository image_tag values_file node_port; do
  [[ -n "${service_name:-}" ]] || continue
  printf "  %-18s %-28s %-36s %-12s\n" "$service_name" "$branch" "${repository}:${image_tag}" "$node_port"
done < "$plan_file"

echo ""
echo "Wait for Argo CD sync, then verify:"
echo "  kubectl get applications -n argocd | grep yas-${target_env}"
echo "  kubectl get pods -n yas-${target_env}"
