#!/usr/bin/env bash
# Create repo .venv with boto3 (amazon.aws) and pytfe (hashicorp.terraform) for localhost runs.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

PYTHON="${PYTHON:-python3}"
if ! command -v "${PYTHON}" >/dev/null 2>&1; then
  echo "python3 not found; set PYTHON= to a valid interpreter" >&2
  exit 1
fi

if [[ ! -d .venv ]]; then
  "${PYTHON}" -m venv .venv
fi

# shellcheck disable=SC1091
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements-python.txt

echo ""
echo "Local venv ready: ${ROOT}/.venv"
echo "  source scripts/load-env.sh   # sets ANSIBLE_PYTHON_INTERPRETER"
echo "  ./scripts/run-day0.sh"
