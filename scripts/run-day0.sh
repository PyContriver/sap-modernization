#!/usr/bin/env bash
# Day 0 with .env loaded
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}" || exit 1
export SAP_MOD_ROOT="${ROOT}"
# shellcheck source=scripts/load-env.sh
source "${ROOT}/scripts/load-env.sh"
ansible-playbook playbooks/day0-infrastructure.yml -e "@${SAP_MOD_EXTRA_VARS_FILE}"
