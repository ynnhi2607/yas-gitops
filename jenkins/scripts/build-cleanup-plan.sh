#!/usr/bin/env bash
set -euo pipefail

target_env="${TARGET_ENV:-dev}"
dockerhub_namespace="${DOCKERHUB_NAMESPACE:-ynnhi2607}"
main_tag="${MAIN_TAG:-latest}"
cleanup_mode="${CLEANUP_MODE:-RESET_TO_MAIN}"
output_file="${1:-cleanup-plan.tsv}"

selected() {
  local env_name="$1"
  [[ "$cleanup_mode" == "RESET_TO_MAIN" || "${!env_name:-false}" == "true" ]]
}

image_name_for() {
  case "$1" in
    storefront-ui) printf 'yas-storefront' ;;
    backoffice-ui) printf 'yas-backoffice' ;;
    *) printf 'yas-%s' "$1" ;;
  esac
}

write_service() {
  local service_name="$1"
  local reset_env="$2"
  local node_port="$3"
  local values_file="environments/${target_env}/services/${service_name}.yaml"
  local repository="${dockerhub_namespace}/$(image_name_for "$service_name")"

  if selected "$reset_env"; then
    printf '%s\tmain\t%s\t%s\t%s\t%s\n' \
      "$service_name" "$repository" "$main_tag" "$values_file" "$node_port" >> "$output_file"
  fi
}

printf '' > "$output_file"

write_service "product"        "RESET_PRODUCT"        "30085"
write_service "cart"           "RESET_CART"           "30088"
write_service "order"          "RESET_ORDER"          "30089"
write_service "customer"       "RESET_CUSTOMER"       "30087"
write_service "inventory"      "RESET_INVENTORY"      "30090"
write_service "location"       "RESET_LOCATION"       "30095"
write_service "tax"            "RESET_TAX"            "30091"
write_service "payment"        "RESET_PAYMENT"        "30096"
write_service "media"          "RESET_MEDIA"          "30086"
write_service "search"         "RESET_SEARCH"         "30092"
write_service "storefront-bff" "RESET_STOREFRONT_BFF" "30082"
write_service "storefront-ui"  "RESET_STOREFRONT_UI"  "30080"
write_service "backoffice-bff" "RESET_BACKOFFICE_BFF" "30083"
write_service "backoffice-ui"  "RESET_BACKOFFICE_UI"  "30081"
write_service "sampledata"     "RESET_SAMPLEDATA"     "30093"

echo "Cleanup plan:"
column -t -s $'\t' "$output_file" 2>/dev/null || cat "$output_file"
