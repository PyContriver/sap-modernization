#!/usr/bin/env bash
# Alias for full AAP setup (see scripts/setup-aap.sh)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "${ROOT}/scripts/setup-aap.sh" "$@"
