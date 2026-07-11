#!/usr/bin/env bash
set -euo pipefail

source_repo_url="${SOURCE_REPO_URL:-https://github.com/ynnhi2607/yas.git}"
target_env="${TARGET_ENV:-dev}"
dockerhub_namespace="${DOCKERHUB_NAMESPACE:-ynnhi2607}"
verify_images="${VERIFY_IMAGES:-true}"
output_file="${1:-developer-build-plan.tsv}"

normalize_branch() {
  local branch="${1:-main}"
  branch="${branch#"${branch%%[![:space:]]*}"}"
  branch="${branch%"${branch##*[![:space:]]}"}"
  branch="${branch#refs/heads/}"
  branch="${branch#origin/}"
  [[ -n "$branch" ]] || branch="main"
  printf '%s' "$branch"
}

resolve_tag() {
  local branch="$1"
  if [[ "$branch" == "main" || "$branch" == "master" || "$branch" == "latest" ]]; then
    printf 'latest'
    return
  fi

  if [[ "$branch" =~ ^[0-9a-fA-F]{7,40}$ ]]; then
    printf '%s' "${branch:0:8}"
    return
  fi

  local commit
  commit="$(git ls-remote "$source_repo_url" "refs/heads/$branch" | awk '{print $1}')"
  if [[ -z "$commit" ]]; then
    echo "ERROR: Cannot resolve branch '$branch' from $source_repo_url" >&2
    exit 1
  fi

  printf '%s' "${commit:0:8}"
}

branch_value() {
  local env_name="$1"
  printf '%s' "${!env_name:-main}"
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
  local branch_env="$2"
  local node_port="$3"
  local branch image_tag image_repo values_file

  branch="$(normalize_branch "$(branch_value "$branch_env")")"
  image_tag="$(resolve_tag "$branch")"
  image_repo="${dockerhub_namespace}/$(image_name_for "$service_name")"
  values_file="environments/${target_env}/services/${service_name}.yaml"

  if [[ ! -f "$values_file" ]]; then
    echo "ERROR: Missing values file: $values_file" >&2
    exit 1
  fi

  if [[ "$verify_images" == "true" && "$branch" != "main" && "$branch" != "master" && "$branch" != "latest" ]]; then
    docker manifest inspect "${image_repo}:${image_tag}" >/dev/null
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$service_name" "$branch" "$image_repo" "$image_tag" "$values_file" "$node_port" >> "$output_file"
}

printf '' > "$output_file"

write_service "product"        "PRODUCT_SERVICE_BRANCH"   "30085"
write_service "cart"           "CART_SERVICE_BRANCH"      "30088"
write_service "order"          "ORDER_SERVICE_BRANCH"     "30089"
write_service "customer"       "CUSTOMER_SERVICE_BRANCH"  "30087"
write_service "inventory"      "INVENTORY_SERVICE_BRANCH" "30090"
write_service "location"       "LOCATION_SERVICE_BRANCH"  "30095"
write_service "tax"            "TAX_SERVICE_BRANCH"       "30091"
write_service "media"          "MEDIA_SERVICE_BRANCH"     "30086"
write_service "payment"        "PAYMENT_SERVICE_BRANCH"   "30096"
write_service "search"         "SEARCH_SERVICE_BRANCH"    "30092"
write_service "storefront-bff" "STOREFRONT_BFF_BRANCH"    "30082"
write_service "storefront-ui"  "STOREFRONT_UI_BRANCH"     "30080"
write_service "backoffice-bff" "BACKOFFICE_BFF_BRANCH"    "30083"
write_service "backoffice-ui"  "BACKOFFICE_UI_BRANCH"     "30081"
write_service "sampledata"     "SAMPLEDATA_BRANCH"        "30093"

echo "Resolved developer build plan:"
column -t -s $'\t' "$output_file" 2>/dev/null || cat "$output_file"
