#!/usr/bin/env bash
# Source secrets from <repo>/.env and build Ansible extra-vars file
# Usage:
#   source /path/to/sap-modernization/scripts/load-env.sh
#   ansible-playbook playbooks/day0-infrastructure.yml -e "@${SAP_MOD_EXTRA_VARS_FILE}"
set -a

_script="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "${_script}")" && pwd)"

ROOT="${SAP_MOD_ROOT:-}"
if [[ -z "${ROOT}" ]]; then
  ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
  if [[ ! -f "${ROOT}/.env.example" ]]; then
    _dir="${PWD}"
    while [[ "${_dir}" != "/" ]]; do
      if [[ -f "${_dir}/.env.example" ]]; then
        ROOT="${_dir}"
        break
      fi
      _dir="$(dirname "${_dir}")"
    done
  fi
fi

ENV_FILE="${ROOT}/.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}" >&2
  echo "  cd ${ROOT:-/path/to/sap-modernization} && cp .env.example .env" >&2
  return 1 2>/dev/null || exit 1
fi

# shellcheck disable=SC1090
source "${ENV_FILE}"

export SAP_MOD_ROOT="${ROOT}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
export TF_TOKEN="${TF_TOKEN:-}"
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN="${ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN:-}"

set +a

# Default example CIDR is not routable — resolve caller public IP for builder SSH unless set explicitly
if [[ -z "${ALLOWED_SSH_CIDR:-}" || "${ALLOWED_SSH_CIDR}" == "203.0.113.0/32" ]]; then
  _detected_ip=""
  if command -v curl >/dev/null 2>&1; then
    _detected_ip="$(curl -fsS --max-time 5 https://checkip.amazonaws.com/ 2>/dev/null | tr -d '[:space:]')"
  fi
  if [[ -n "${_detected_ip}" ]]; then
    ALLOWED_SSH_CIDR="${_detected_ip}/32"
    echo "Resolved ALLOWED_SSH_CIDR=${ALLOWED_SSH_CIDR} (your public IP for builder SSH)" >&2
  else
    echo "Warning: set ALLOWED_SSH_CIDR in .env to your public IP/32 (builder SSH will fail with 203.0.113.0/32)" >&2
  fi
fi

# EC2 SSH private key for builder / golden-image plays (must match SSH_KEY_NAME)
if [[ -z "${SSH_PRIVATE_KEY_FILE:-}" && -n "${SSH_KEY_NAME:-}" ]]; then
  for _key_candidate in \
    "${HOME}/.ssh/${SSH_KEY_NAME}.pem" \
    "${HOME}/.ssh/${SSH_KEY_NAME}" \
    "${HOME}/${SSH_KEY_NAME}.pem" \
    "${HOME}/Downloads/${SSH_KEY_NAME}.pem"; do
    if [[ -f "${_key_candidate}" ]]; then
      SSH_PRIVATE_KEY_FILE="${_key_candidate}"
      echo "Resolved SSH_PRIVATE_KEY_FILE=${SSH_PRIVATE_KEY_FILE}" >&2
      break
    fi
  done
fi

if [[ -n "${SSH_PRIVATE_KEY_FILE:-}" && -f "${SSH_PRIVATE_KEY_FILE}" ]]; then
  _key_mode="$(stat -f '%Lp' "${SSH_PRIVATE_KEY_FILE}" 2>/dev/null || stat -c '%a' "${SSH_PRIVATE_KEY_FILE}" 2>/dev/null || echo '')"
  if [[ -n "${_key_mode}" && "${_key_mode}" != "600" && "${_key_mode}" != "400" ]]; then
    if chmod 600 "${SSH_PRIVATE_KEY_FILE}" 2>/dev/null; then
      echo "Adjusted SSH key permissions to 600: ${SSH_PRIVATE_KEY_FILE}" >&2
    else
      echo "Warning: run chmod 600 ${SSH_PRIVATE_KEY_FILE} (current mode ${_key_mode})" >&2
    fi
  fi
fi

SAP_MOD_EXTRA_VARS_FILE="${ROOT}/.ansible-extra-vars.yml"
{
  echo "---"
  echo "terraform_driver: \"${TERRAFORM_DRIVER:-hcp}\""
  [[ -n "${HCP_TERRAFORM_ORGANIZATION:-}" ]] && echo "hcp_terraform_organization: \"${HCP_TERRAFORM_ORGANIZATION}\""
  [[ -n "${HCP_TERRAFORM_WORKSPACE:-}" ]] && echo "hcp_terraform_workspace: \"${HCP_TERRAFORM_WORKSPACE}\""
  [[ -n "${HCP_TERRAFORM_WORKSPACE_ID:-}" ]] && echo "hcp_terraform_workspace_id: \"${HCP_TERRAFORM_WORKSPACE_ID}\""
  if [[ -n "${BASE_AMI_ID:-}" ]] && [[ "${BASE_AMI_ID}" != "ami-xxxxxxxxxxxxxxxxx" ]] \
    && ! [[ "${BASE_AMI_ID}" =~ [xX]{6,} ]]; then
    echo "base_ami_id: \"${BASE_AMI_ID}\""
  fi
  [[ -n "${SSH_KEY_NAME:-}" ]] && echo "ssh_key_name: \"${SSH_KEY_NAME}\""
  [[ -n "${SSH_PRIVATE_KEY_FILE:-}" ]] && echo "builder_ssh_private_key_file: \"${SSH_PRIVATE_KEY_FILE}\""
  [[ -n "${ALLOWED_SSH_CIDR:-}" ]] && echo "allowed_ssh_cidr: \"${ALLOWED_SSH_CIDR}\""
  [[ -n "${AWS_DEFAULT_REGION:-}" ]] && echo "aws_region: \"${AWS_DEFAULT_REGION}\""
  [[ -n "${GOLDEN_AMI_ID:-}" ]] && echo "golden_ami_id: \"${GOLDEN_AMI_ID}\""
  [[ -n "${GOLDEN_IMAGE_METHOD:-}" ]] && echo "golden_image_method: \"${GOLDEN_IMAGE_METHOD}\""
  if [[ -f "${ROOT}/.venv/bin/python" ]]; then
    echo "sap_mod_local_python: \"${ROOT}/.venv/bin/python\""
  fi
} > "${SAP_MOD_EXTRA_VARS_FILE}"

export SAP_MOD_ROOT
export SAP_MOD_EXTRA_VARS_FILE
# Controller venv only — do NOT set ANSIBLE_PYTHON_INTERPRETER (would break remote EC2 modules)
if [[ -f "${ROOT}/.venv/bin/python" ]]; then
  export SAP_MOD_VENV_PYTHON="${ROOT}/.venv/bin/python"
  _py="${ROOT}/.venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
  _py="$(command -v python3)"
fi
if [[ -n "${_py:-}" ]]; then
  if ! "${_py}" -c "import boto3" 2>/dev/null; then
    echo "Warning: boto3 not found for ${_py}. Run: ./scripts/setup-local-venv.sh" >&2
  fi
  if ! "${_py}" -c "import pytfe" 2>/dev/null; then
    echo "Warning: pytfe not found for ${_py}. Run: ./scripts/setup-local-venv.sh" >&2
  fi
fi

echo "Loaded ${ENV_FILE}"
echo "  SAP_MOD_ROOT=${SAP_MOD_ROOT}"
echo "  AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}"
echo "  TF_TOKEN=${TF_TOKEN:+set}"
echo "  ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN=${ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN:+set}"
echo "  SAP_MOD_EXTRA_VARS_FILE=${SAP_MOD_EXTRA_VARS_FILE}"
echo "  SAP_MOD_VENV_PYTHON=${SAP_MOD_VENV_PYTHON:-not set (localhost uses group_vars/localhost.yml)}"
echo "  SSH_PRIVATE_KEY_FILE=${SSH_PRIVATE_KEY_FILE:-not set}"
echo ""
echo "Run Day 0:"
echo "  ./scripts/run-day0.sh"
echo "Or:"
echo "  ansible-playbook playbooks/day0-infrastructure.yml -e @${SAP_MOD_EXTRA_VARS_FILE}"
