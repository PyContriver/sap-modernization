#!/usr/bin/env bash
# Push .env secrets to AAP credentials + job template extra_vars
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}" || exit 1

if [[ -z "${CONTROLLER_HOST:-}" ]]; then
  # shellcheck disable=SC1090
  source "${ROOT}/scripts/load-env-aap.sh"
fi

if ! ansible-galaxy collection list ansible.controller 2>/dev/null | grep -q ansible.controller; then
  echo "Installing ansible.controller collection..."
  ansible-galaxy collection install -r "${ROOT}/requirements-aap-bootstrap.yml" -p "${ROOT}/collections"
  export ANSIBLE_COLLECTIONS_PATH="${ROOT}/collections:${ANSIBLE_COLLECTIONS_PATH:-}"
fi

ansible-playbook playbooks/aap-bootstrap.yml \
  -e "@${SAP_MOD_EXTRA_VARS_FILE}" \
  -e "builder_ssh_private_key_file=${SSH_PRIVATE_KEY_FILE:-}"
