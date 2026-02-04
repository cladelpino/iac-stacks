#!/usr/bin/env bash
set -euo pipefail

bucket="$1"
prefix="$2"

now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Enumerate stacks from repo folders
mapfile -t stacks < <(find stacks -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)

enabled=()

for s in "${stacks[@]}"; do
  # Get newest event key: because our key uses reverse timestamp, newest sorts first.
  key="$(aws s3api list-objects-v2 \
    --bucket "$bucket" \
    --prefix "${prefix}/events/${s}/" \
    --max-keys 1 \
    --query "Contents[0].Key" \
    --output text 2>/dev/null || true)"

  if [[ -z "$key" || "$key" == "None" ]]; then
    # default DISABLED
    continue
  fi

  obj="$(aws s3 cp "s3://${bucket}/${key}" -)"

  type="$(jq -r '.type' <<<"$obj")"
  expires_at="$(jq -r '.payload.expires_at // empty' <<<"$obj")"

  if [[ "$type" == "DISABLE" ]]; then
    continue
  fi

  # ENABLE: must not be expired
  if [[ -n "$expires_at" && "$expires_at" > "$now" ]]; then
    enabled+=("$s")
  fi
done

jq -n --argjson arr "$(printf '%s\n' "${enabled[@]}" | jq -R . | jq -s .)" \
  '{enabled: $arr}'
