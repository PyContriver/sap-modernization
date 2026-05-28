#!/usr/bin/env bash
# Install collections for hashicorp.terraform (Automation Hub) + AWS/Ansible
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -z "${ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN:-}" ]]; then
  echo "Set Automation Hub token first:"
  echo "  export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN='...'"
  echo "Get token: https://console.redhat.com/ansible/automation-hub/token"
  exit 1
fi

echo "Installing from requirements.yml (hashicorp.terraform via Automation Hub)..."
ansible-galaxy collection install -r requirements.yml -p "${ROOT}/collections" --force

echo ""
echo "Add to your shell or ansible.cfg:"
echo "  export ANSIBLE_COLLECTIONS_PATH=${ROOT}/collections"
echo ""
ansible-galaxy collection list hashicorp.terraform -p "${ROOT}/collections" || true
