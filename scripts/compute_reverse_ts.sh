#!/usr/bin/env bash
set -euo pipefail

# Epoch ms (forward)
now_ms="$(date -u +%s%3N)"

# 16-digit max (keeps lexicographic order stable)
max="9999999999999999"

rev=$((max - now_ms))

# zero-pad to 16 digits
printf "%016d %s\n" "$rev" "$now_ms"
