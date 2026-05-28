#!/usr/bin/env bash
# Load .env (SAP secrets) + .env.aap (Controller API) for aap-bootstrap playbook
# Usage:
#   source scripts/load-env-aap.sh
#   ./scripts/setup-aap.sh
#
# Do not use "set -e" here — this file is sourced into your interactive shell.

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

CONTROLLER_HOST="${CONTROLLER_HOST%/}"
export CONTROLLER_HOST="${CONTROLLER_HOST:-}"
export CONTROLLER_OAUTH_TOKEN="${CONTROLLER_OAUTH_TOKEN:-}"
export CONTROLLER_USERNAME="${CONTROLLER_USERNAME:-}"
export CONTROLLER_PASSWORD="${CONTROLLER_PASSWORD:-}"
export AAP_ORGANIZATION="${AAP_ORGANIZATION:-Default}"
export AAP_VERIFY_SSL="${AAP_VERIFY_SSL:-true}"

# IP-based controllers almost always use self-signed TLS — avoid CERTIFICATE_VERIFY_FAILED
if [[ "${AAP_VERIFY_SSL}" == "true" && "${CONTROLLER_HOST}" =~ ^https?://[0-9]{1,3}(\.[0-9]{1,3}){3}(/|$) ]]; then
  echo "NOTE: ${CONTROLLER_HOST} is an IP — using AAP_VERIFY_SSL=false (set AAP_VERIFY_SSL=true to force verify)" >&2
  AAP_VERIFY_SSL=false
fi

# ansible.controller / awx.awx connection (see collection docs)
export CONTROLLER_VERIFY_SSL="${AAP_VERIFY_SSL}"
if [[ -n "${CONTROLLER_OAUTH_TOKEN:-}" ]]; then
  export CONTROLLER_OAUTH_TOKEN
else
  unset CONTROLLER_OAUTH_TOKEN 2>/dev/null || true
fi
if [[ -n "${CONTROLLER_USERNAME:-}" ]]; then
  export CONTROLLER_USERNAME
  export CONTROLLER_PASSWORD="${CONTROLLER_PASSWORD:-}"
fi

echo ""
echo "AAP bootstrap env:"
echo "  CONTROLLER_HOST=${CONTROLLER_HOST}"
echo "  CONTROLLER_OAUTH_TOKEN=${CONTROLLER_OAUTH_TOKEN:+set}"
echo "  CONTROLLER_USERNAME=${CONTROLLER_USERNAME:-}"
echo "  AAP_ORGANIZATION=${AAP_ORGANIZATION}"
echo "  AAP_VERIFY_SSL=${AAP_VERIFY_SSL}"
echo ""
echo "Provision AAP (project, inventory, JT, workflow):"
echo "  ./scripts/setup-aap.sh"
