"""Convert terraform_variables dict to hashicorp.terraform.run variables list (HCL-encoded)."""

from __future__ import annotations

import json
from typing import Any

# Types aligned with terraform/variables.tf — HCP validates variable values as HCL.
_TF_VAR_TYPES: dict[str, str] = {
    "aws_region": "string",
    "environment": "string",
    "project_name": "string",
    "vpc_cidr": "string",
    "base_ami_id": "string",
    "golden_ami_id": "string",
    "instance_type_builder": "string",
    "instance_type_sap": "string",
    "instance_type_db2": "string",
    "image_builder_version": "string",
    "ssh_key_name": "string",
    "allowed_ssh_cidr": "string",
    "sap_sid": "string",
    "db2_instance_name": "string",
    "deploy_builder": "bool",
    "deploy_image_builder": "bool",
    "deploy_sap_stack": "bool",
    "db2_port": "number",
    "image_builder_instance_types": "list",
    "additional_tags": "map",
}


def _hcl_string(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def _hcl_bool(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    normalized = str(value).strip().lower()
    return "true" if normalized in ("true", "1", "yes", "on") else "false"


def _hcl_number(value: Any) -> str:
    if isinstance(value, bool):
        raise ValueError("boolean is not a valid number for HCL encoding")
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        return str(int(value)) if value.is_integer() else str(value)
    text = str(value).strip()
    if text.isdigit() or (text.startswith("-") and text[1:].isdigit()):
        return text
    try:
        numeric = float(text)
    except ValueError as exc:
        raise ValueError(f"invalid number literal for HCL: {value!r}") from exc
    return str(int(numeric)) if numeric.is_integer() else str(numeric)


def _hcl_list(value: Any) -> str:
    if isinstance(value, str):
        text = value.strip()
        if text.startswith("[") and text.endswith("]"):
            return text
        items = [part.strip() for part in text.split(",") if part.strip()]
    elif isinstance(value, (list, tuple)):
        items = [str(item) for item in value]
    else:
        items = [str(value)]
    return json.dumps(items)


def _hcl_map(value: Any) -> str:
    if isinstance(value, dict):
        payload = value
    elif isinstance(value, str):
        text = value.strip()
        if not text:
            return "{}"
        payload = json.loads(text)
    else:
        raise ValueError(f"cannot encode map for HCL: {value!r}")
    return json.dumps(payload)


def terraform_hcl_value(key: str, value: Any, var_type: str | None = None) -> str:
    """Encode a Terraform input value as HCL for HCP run variables."""
    resolved_type = var_type or _TF_VAR_TYPES.get(key, "string")

    if resolved_type == "bool":
        return _hcl_bool(value)
    if resolved_type == "number":
        return _hcl_number(value)
    if resolved_type == "list":
        return _hcl_list(value)
    if resolved_type == "map":
        return _hcl_map(value)
    return _hcl_string(str(value))


def terraform_hcp_vars(terraform_variables: dict | None) -> list[dict[str, str]]:
    result = []
    for key, value in (terraform_variables or {}).items():
        result.append(
            {
                "key": str(key),
                "value": terraform_hcl_value(str(key), value),
                "category": "terraform",
            }
        )
    return result


class FilterModule:
    def filters(self):
        return {
            "terraform_hcp_vars": terraform_hcp_vars,
            "terraform_hcl_value": terraform_hcl_value,
        }
