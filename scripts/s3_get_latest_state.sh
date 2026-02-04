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

  # Extract fields from our known JSON shape without jq.
  # "type" line looks like:   "type": "ENABLE",
  type="$(printf '%s\n' "$obj" | awk -F'"' '/"type"/ {print $4; exit}')"

  # "expires_at" line looks like: "expires_at": "2026-02-10T00:00:00Z" or "expires_at": null
  expires_line="$(printf '%s\n' "$obj" | grep '"expires_at"' || true)"
  expires_at=""
  if [[ -n "$expires_line" && "$expires_line" != *null* ]]; then
    expires_at="$(printf '%s\n' "$expires_line" | awk -F'"' '{print $4}')"
  fi

  if [[ "$type" == "DISABLE" ]]; then
    continue
  fi

  # ENABLE: must not be expired
  if [[ -n "$expires_at" && "$expires_at" > "$now" ]]; then
    enabled+=("$s")
  fi
done

for i in "${!enabled[@]}"; do
  s="${enabled[$i]}"
  if (( i > 0 )); then
    printf ','
  fi
  printf '%s' "$s"
done
printf '\n'
