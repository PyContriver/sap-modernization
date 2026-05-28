#!/usr/bin/env bash
# Load .env (SAP secrets) + .env.aap (Controller API) for aap-bootstrap playbook
# Usage:
#   source scripts/load-env-aap.sh
#   ./scripts/bootstrap-aap.sh
set -euo pipefail

_script="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "${_script}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# SAP demo vars, SSH key path, optional ALLOWED_SSH_CIDR resolution
# shellcheck disable=SC1090
source "${SCRIPT_DIR}/load-env.sh"

AAP_ENV="${ROOT}/.env.aap"
if [[ ! -f "${AAP_ENV}" ]]; then
  echo "Missing ${AAP_ENV}" >&2
  echo "  cp ${ROOT}/.env.aap.example ${AAP_ENV}" >&2
  return 1 2>/dev/null || exit 1
fi

set -a
# shellcheck disable=SC1090
source "${AAP_ENV}"
set +a

export CONTROLLER_HOST="${CONTROLLER_HOST:-}"
export CONTROLLER_OAUTH_TOKEN="${CONTROLLER_OAUTH_TOKEN:-}"
export CONTROLLER_USERNAME="${CONTROLLER_USERNAME:-}"
export CONTROLLER_PASSWORD="${CONTROLLER_PASSWORD:-}"
export AAP_ORGANIZATION="${AAP_ORGANIZATION:-Default}"
export AAP_VERIFY_SSL="${AAP_VERIFY_SSL:-true}"

# ansible.controller / awx.awx connection (see collection docs)
export CONTROLLER_VERIFY_SSL="${AAP_VERIFY_SSL}"
if [[ -n "${CONTROLLER_OAUTH_TOKEN:-}" ]]; then
  export CONTROLLER_OAUTH_TOKEN
fi

echo ""
echo "AAP bootstrap env:"
echo "  CONTROLLER_HOST=${CONTROLLER_HOST}"
echo "  CONTROLLER_OAUTH_TOKEN=${CONTROLLER_OAUTH_TOKEN:+set}"
echo "  AAP_ORGANIZATION=${AAP_ORGANIZATION}"
echo ""
echo "Upload credentials:"
echo "  ./scripts/bootstrap-aap.sh"
