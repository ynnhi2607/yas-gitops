#!/usr/bin/env bash
set -euo pipefail

plan_file="${1:-developer-build-plan.tsv}"

if [[ ! -f "$plan_file" ]]; then
  echo "Plan file not found: $plan_file" >&2
  exit 1
fi

update_value() {
  local values_file="$1"
  local repository="$2"
  local tag="$3"

  sed -i "s#^\([[:space:]]*repository:\).*#\1 ${repository}#" "$values_file"
  sed -i "s#^\([[:space:]]*tag:\).*#\1 ${tag}#" "$values_file"
}

while IFS=$'\t' read -r service_name branch repository image_tag values_file node_port; do
  [[ -n "${service_name:-}" ]] || continue
  echo "Updating ${values_file}: ${repository}:${image_tag} (${service_name}, branch=${branch})"
  update_value "$values_file" "$repository" "$image_tag"
done < "$plan_file"

echo "GitOps values diff:"
git diff -- environments/*/services/*.yaml || true
