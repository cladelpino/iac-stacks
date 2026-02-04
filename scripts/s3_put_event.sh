#!/usr/bin/env bash
set -euo pipefail

bucket="$1"         # e.g. my-registry-bucket
prefix="$2"         # e.g. v1
stack_id="$3"       # e.g. alpha
type="$4"           # ENABLE or DISABLE
expires_at="${5:-}" # required for ENABLE
runid="$6"          # github run id or uuid

read -r rev now_ms < <(./scripts/compute_reverse_ts.sh)

ts="$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"

key="${prefix}/events/${stack_id}/${rev}_${now_ms}_${runid}_${type}.json"

if [[ "$type" == "ENABLE" && -z "$expires_at" ]]; then
  echo "ENABLE requires expires_at (RFC3339 UTC, e.g. 2026-02-05T00:00:00Z)" >&2
  exit 1
fi

if [[ "$type" == "ENABLE" ]]; then
  # For ENABLE events, expires_at must be a timestamp string.
  expires_json="\"$expires_at\""
else
  # For DISABLE (or other types), store null.
  expires_json="null"
fi

tmp="$(mktemp)"
cat > "$tmp" <<JSON
{
  "event_version": 1,
  "type": "$type",
  "stack_id": "$stack_id",
  "created_at": "$ts",
  "payload": {
    "expires_at": $expires_json
  }
}
JSON

aws s3 cp "$tmp" "s3://${bucket}/${key}" --content-type "application/json" >/dev/null
echo "$key"
