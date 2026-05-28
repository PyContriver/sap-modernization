#!/usr/bin/env bash
# Build and push sap-mod-ee, then register on AAP (requires podman + Hub token in .env for pull)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

# shellcheck disable=SC1090
source "${ROOT}/scripts/load-env.sh"
# shellcheck disable=SC1090
source "${ROOT}/scripts/load-env-aap.sh"

EE_NAME="${AAP_EXECUTION_ENVIRONMENT:-sap-mod-ee}"
EE_IMAGE="${AAP_EE_IMAGE:-34.205.23.227/demo/${EE_NAME}:latest}"
EE_BASE="${AAP_EE_BASE_IMAGE:-34.205.23.227/ee-supported-rhel9:latest}"
EE_DIR="${ROOT}/execution-environment"
PLATFORM="${PODMAN_DEFAULT_PLATFORM:-linux/amd64}"

CONTAINER_CMD="${CONTAINER_CMD:-}"
if [[ -z "${CONTAINER_CMD}" ]]; then
  if command -v podman >/dev/null 2>&1; then
    CONTAINER_CMD=podman
  elif command -v docker >/dev/null 2>&1; then
    CONTAINER_CMD=docker
  else
    echo "Need podman or docker" >&2
    exit 1
  fi
fi

echo "Pulling base image ${EE_BASE}..."
"${CONTAINER_CMD}" pull --tls-verify=false --platform "${PLATFORM}" "${EE_BASE}" 2>/dev/null \
  || "${CONTAINER_CMD}" pull --platform "${PLATFORM}" "${EE_BASE}"

echo "Building ${EE_IMAGE} (pytfe + hashicorp.terraform>=2.0, platform ${PLATFORM})..."
if [[ -z "${ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN:-}" ]]; then
  echo "ERROR: set ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN in .env (Automation Hub) before building EE" >&2
  exit 1
fi

_STAGING="${EE_DIR}/.collections-staging"
rm -rf "${_STAGING}"
mkdir -p "${_STAGING}"
echo "Staging hashicorp.terraform 2.0.0 for EE (Automation Hub)..."
export ANSIBLE_CONFIG="${ROOT}/ansible.cfg"
ansible-galaxy collection install 'hashicorp.terraform:2.0.0' \
  -p "${_STAGING}" --force
_staged_ver="$(python3 -c "import json; print(json.load(open('${_STAGING}/ansible_collections/hashicorp/terraform/MANIFEST.json'))['collection_info']['version'])")"
echo "Staged hashicorp.terraform ${_staged_ver}"
[[ "${_staged_ver}" == 2.* ]] || { echo "ERROR: expected 2.x, got ${_staged_ver}" >&2; exit 1; }

echo "Building image (no cache for collection layer)..."
"${CONTAINER_CMD}" build --no-cache \
  --platform "${PLATFORM}" \
  -f "${EE_DIR}/Containerfile.sap-mod-ee" \
  -t "${EE_IMAGE}" \
  "${EE_DIR}"

echo "Verify hashicorp.terraform in built image..."
"${CONTAINER_CMD}" run --rm "${EE_IMAGE}" python3 -c \
  "import json; v=json.load(open('/opt/sap-mod-ee/collections/ansible_collections/hashicorp/terraform/MANIFEST.json'))['collection_info']['version']; print(v); assert v.startswith('2.')"

REGISTRY="${EE_IMAGE%%/*}"
echo "Pushing to ${REGISTRY}..."
if [[ -n "${CONTROLLER_USERNAME:-}" && -n "${CONTROLLER_PASSWORD:-}" ]]; then
  echo "${CONTROLLER_PASSWORD}" | "${CONTAINER_CMD}" login "${REGISTRY}" -u "${CONTROLLER_USERNAME}" --password-stdin --tls-verify=false 2>/dev/null \
    || echo "${CONTROLLER_PASSWORD}" | "${CONTROLLER_CMD}" login "${REGISTRY}" -u "${CONTROLLER_USERNAME}" --password-stdin
fi
"${CONTAINER_CMD}" push --tls-verify=false "${EE_IMAGE}" 2>/dev/null || "${CONTAINER_CMD}" push "${EE_IMAGE}"

COLLECTIONS_PATH="${ROOT}/collections"
if ! ansible-galaxy collection list ansible.controller -p "${COLLECTIONS_PATH}" 2>/dev/null | grep -q ansible.controller; then
  ansible-galaxy collection install -r "${ROOT}/requirements-aap-bootstrap.yml" -p "${COLLECTIONS_PATH}"
fi
export ANSIBLE_COLLECTIONS_PATH="${COLLECTIONS_PATH}:${ANSIBLE_COLLECTIONS_PATH:-}"

ansible-playbook "${ROOT}/playbooks/aap-register-ee.yml" \
  -e "aap_ee_name=${EE_NAME}" \
  -e "aap_ee_image=${EE_IMAGE}" \
  -e "aap_organization=${AAP_ORGANIZATION:-Default}"

echo ""
echo "Updating job templates to use ${EE_NAME}..."
"${ROOT}/scripts/setup-aap.sh" --tags extra_vars --tags job_templates --tags workflow

echo "Done: ${EE_NAME} -> ${EE_IMAGE}"
