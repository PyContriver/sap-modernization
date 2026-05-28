from __future__ import annotations

import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "roles/terraform_infra/filter_plugins"))

from terraform_hcp_vars import terraform_hcl_value, terraform_hcp_vars  # noqa: E402


@pytest.mark.parametrize(
    ("key", "value", "expected"),
    [
        ("allowed_ssh_cidr", "203.0.113.0/32", '"203.0.113.0/32"'),
        ("image_builder_version", "1.0.0", '"1.0.0"'),
        ("base_ami_id", "ami-0123456789abcdef0", '"ami-0123456789abcdef0"'),
        ("deploy_builder", True, "true"),
        ("deploy_builder", "False", "false"),
        ("db2_port", 50000, "50000"),
    ],
)
def test_terraform_hcl_value(key: str, value: object, expected: str) -> None:
    assert terraform_hcl_value(key, value) == expected


def test_terraform_hcp_vars_wraps_strings() -> None:
    encoded = terraform_hcp_vars(
        {
            "allowed_ssh_cidr": "203.0.113.0/32",
            "image_builder_version": "1.0.0",
        }
    )
    assert encoded == [
        {"key": "allowed_ssh_cidr", "value": '"203.0.113.0/32"', "category": "terraform"},
        {"key": "image_builder_version", "value": '"1.0.0"', "category": "terraform"},
    ]
