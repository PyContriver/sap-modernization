#!/usr/bin/env bash
# Full AAP setup: project, inventory, credentials, job templates, workflow
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}" || exit 1

# shellcheck disable=SC1090
source "${ROOT}/scripts/load-env-aap.sh"

COLLECTIONS_PATH="${ROOT}/collections"
if ! ansible-galaxy collection list ansible.controller -p "${COLLECTIONS_PATH}" 2>/dev/null | grep -q ansible.controller; then
  echo "Installing ansible.controller..."
  ansible-galaxy collection install -r "${ROOT}/requirements-aap-bootstrap.yml" -p "${COLLECTIONS_PATH}"
fi
export ANSIBLE_COLLECTIONS_PATH="${COLLECTIONS_PATH}:${ANSIBLE_COLLECTIONS_PATH:-}"

# Force builder SSH CIDR from .env (never laptop auto-detect on this playbook)
_allowed_cidr="${ALLOWED_SSH_CIDR:-0.0.0.0/0}"
echo "Using allowed_ssh_cidr=${_allowed_cidr} for AAP job template extra_vars" >&2

set +e
ansible-playbook playbooks/aap-setup.yml \
  -e "@${SAP_MOD_EXTRA_VARS_FILE}" \
  -e "allowed_ssh_cidr=${_allowed_cidr}" \
  -e "builder_ssh_private_key_file=${SSH_PRIVATE_KEY_FILE:-}" \
  "$@"
rc=$?
set -e
if [[ "${rc}" -ne 0 ]]; then
  echo "" >&2
  echo "AAP setup failed (exit ${rc:-1})." >&2
  echo "  SSL error? Set AAP_VERIFY_SSL=false in .env.aap for IP/self-signed controllers." >&2
  echo "  No playbooks? Push requirements.yml (public Galaxy) to SCM, sync project in AAP, then:" >&2
  echo "    ./scripts/setup-aap.sh --tags job_templates --tags workflow" >&2
  echo "  Re-load env: source scripts/load-env-aap.sh && ./scripts/setup-aap.sh" >&2
  exit "${rc}"
fi
