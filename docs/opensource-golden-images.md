# Open-source options for Packer (golden images)

This repo does **not** require HashiCorp Packer. Three golden-image paths are available:

## Recommendation for OSS demos

| Priority | Method | License / cost | Binary needed |
|----------|--------|----------------|---------------|
| **1** | `golden_image_method: ansible` | Ansible GPL, AWS API | Ansible only |
| **2** | `golden_image_method: image_builder` | AWS service (no Packer) | AWS CLI |
| **3** | `golden_image_method: packer` | Packer **BSL** (not OSI OSS) | `packer` CLI |

Use **`ansible`** or **`image_builder`** when you need a truly open-source or license-friendly demo.

Use **`packer`** when you want slides to say “Terraform → **Packer** → deploy” and you accept the [HashiCorp BSL](https://www.hashicorp.com/license) for the Packer binary.

## Path 1 — Ansible + `ec2_ami` (default, OSS)

Same roles as Packer (`sap_os_prep`, `db2_prep`), but orchestration is 100% Ansible:

```bash
ansible-playbook playbooks/site.yml
```

## Path 2 — EC2 Image Builder (OSS-friendly on AWS)

AWS-managed build instance; component bash mirrors the roles:

```bash
ansible-playbook playbooks/site-imagebuilder.yml
```

## Path 3 — Packer HCL (classic demo)

Templates in `packer/` use the **ansible provisioner** pointing at the same roles:

```bash
# Install Packer: https://developer.hashicorp.com/packer/install
cd packer && packer init sap-db2-golden.pkr.hcl
ansible-playbook ../playbooks/site-packer.yml
```

Or manual:

```bash
cp packer/packer.auto.pkrvars.hcl.example packer/packer.auto.pkrvars.hcl
# edit source_ami, region
cd packer && packer build sap-db2-golden.pkr.hcl
```

AAP job template: run `01-terraform-infra-packer.yml` → `02-golden-image.yml -e golden_image_method=packer` → `03-deploy-sap.yml`.

## What is NOT in this repo

| Tool | Status |
|------|--------|
| HashiCorp Packer binary | Optional; installed on EE/controller |
| OpenTofu | IaC only; does not build AMIs |
| “OpenPacker” fork | No widely adopted fork like OpenTofu |

## Pipeline comparison

```text
ansible:        Terraform → builder EC2 → Ansible roles → ec2_ami
image_builder:  Terraform → Image Builder pipeline → AMI
packer:         Terraform (VPC) → packer build → AMI (ansible provisioner inside)
```
