# SAP Modernization — PPT-aligned (HCP + IBM Db2)

Ansible Automation Platform orchestrates **HCP Terraform** (`hashicorp.terraform`), **Ansible golden images** (Packer replacement), and **IBM Db2 + SAP** install/ops playbooks on AWS.

**Not in scope:** SAP HANA / `hdblcm` / HSR — database tier is **IBM Db2**.

## PPT story → repository

| Day | Slides | Implementation |
|-----|--------|----------------|
| **0** | `hashicorp.terraform` / pre & post-flight / inventory / rollback | `day0-infrastructure.yml`, roles `terraform_*` |
| **0.5** | Ansible golden images (PPT Packer+Ansible provisioner) | `day05-golden-image.yml`, `golden_image` |
| **0 deploy** | Terraform launches SAP+Db2 from golden AMI | `day0-deploy-workload.yml`, `sap_deploy` |
| **1** | OS prep, **Db2 install**, SWPM, validate | `day1-install.yml`, `db2_install`, `sap_swpm_install` |
| **2** | Start/stop, patch, backup, compliance | `day2-operations.yml` (tagged stubs) |

Full guide: **[docs/ppt-story-and-aap-workflow.md](docs/ppt-story-and-aap-workflow.md)**

## Architecture

```text
AAP Workflow
  Day 0:  preflight → hashicorp.terraform (HCP) → postflight → inventory sync
  Day 0.5: Ansible golden AMI (same roles as Day 1 OS prep)
  Deploy:  hashicorp.terraform (golden_ami_id) → inventory sync
  Day 1:   sap_general_preconfigure → sap_db2_preconfigure → db2_install → SWPM → validate
  Day 2:   operations (--tags start|stop|patch|backup)
```

## Local secrets (`.env`)

```bash
cp .env.example .env   # fill AH token, TF_TOKEN, AWS keys, base_ami_id
source scripts/load-env.sh
ansible-playbook playbooks/day0-infrastructure.yml -e "@${SAP_MOD_EXTRA_VARS_FILE}"
```

`.env` is gitignored.

## Quick start (AAP)

1. Configure `group_vars/all.yml` — HCP org/workspace, `TF_TOKEN` credential.
2. Configure `group_vars/demo/aws.yml` — `base_ami_id`, `ssh_key_name`.
3. Workflow job templates (see docs):
   - `playbooks/day0-infrastructure.yml`
   - `playbooks/day05-golden-image.yml`
   - `playbooks/day0-deploy-workload.yml` (pass `golden_ami_id` from workflow stats)
   - `playbooks/day1-install.yml`

Or one job: `playbooks/site.yml` with `-e run_day1=true` when ready.

## Terraform driver

| Driver | Collection | Use |
|--------|------------|-----|
| **`hcp`** (default) | `hashicorp.terraform` | HCP Terraform / TFE workspace state |
| `local` | `cloud.terraform` | CLI + S3 (`playbooks/local-terraform-only.yml`) |

## Golden image (Day 0.5)

| Method | Variable | Notes |
|--------|----------|--------|
| **Ansible** (default) | `golden_image_method: ansible` | PPT “Packer replacement” |
| EC2 Image Builder | `image_builder` | AWS-native |
| Packer | `packer` | Optional BSL binary |

## IBM Db2 vs HANA (Day 1)

| PPT (HANA) | This repo |
|------------|-----------|
| `sap_hana_preconfigure` | `sap_db2_preconfigure` |
| `sap_hana_install` | `db2_install` |
| HANA HSR | Db2 HADR (Day 2 stub) |

Enable real installs with `db2_perform_install: true` and licensed media paths (see `group_vars/all.yml`).

## Collections

| Where | Command |
|-------|---------|
| **Local test** | `ansible-galaxy collection install -r requirements-local.yml` |
| **AAP / HCP** | `ansible-galaxy collection install -r requirements-aap.yml` (Automation Hub token required) |

`hashicorp.terraform` is **not** on public Galaxy — only [Automation Hub](https://console.redhat.com/ansible/automation-hub). See [docs/local-testing.md](docs/local-testing.md).

`cloud.terraform`, `amazon.aws`, `ansible.posix` install from Galaxy everywhere.

## Layout

```text
playbooks/day0-infrastructure.yml   # Day 0
playbooks/day05-golden-image.yml      # Day 0.5
playbooks/day0-deploy-workload.yml
playbooks/day1-install.yml            # Day 1
playbooks/day2-operations.yml           # Day 2
playbooks/site.yml                    # Full pipeline
roles/terraform_preflight|postflight|inventory|rollback
roles/sap_general_preconfigure|sap_db2_preconfigure|db2_install|...
terraform/                            # HCP-uploaded AWS modules
docs/ppt-story-and-aap-workflow.md
```

## AAP credentials

- **HCP:** `TF_TOKEN` → `hashicorp.terraform`
- **AWS:** EC2, AMI, Image Builder
- **SSH:** builder and private hosts (bastion/SSM for Day 1)

See [docs/aap-30min-setup.md](docs/aap-30min-setup.md) (step-by-step AAP setup), [docs/aap-job-templates.md](docs/aap-job-templates.md), [docs/aap-bootstrap.md](docs/aap-bootstrap.md) (`./scripts/setup-aap.sh` provisions AAP via API), and [docs/hcp-terraform-setup.md](docs/hcp-terraform-setup.md).
