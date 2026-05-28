# Ansible Automation Platform job templates

## Execution environment

Include collections from `requirements.yml`:

- `hashicorp.terraform`
- `cloud.terraform`
- `amazon.aws`
- `ansible.posix`

Terraform CLI binary must be on the EE image when `terraform_driver: local`.

## PPT workflow (recommended)

See **[ppt-story-and-aap-workflow.md](ppt-story-and-aap-workflow.md)** for the four-node workflow (Day 0 → 0.5 → deploy → Day 1).

| Node | Playbook |
|------|----------|
| 1 | `playbooks/day0-infrastructure.yml` |
| 2 | `playbooks/day05-golden-image.yml` |
| 3 | `playbooks/day0-deploy-workload.yml` |
| 4 | `playbooks/day1-install.yml` |
| — | `playbooks/day2-operations.yml` (`--tags start`) |

## Legacy / phased job templates

| Order | Playbook | Purpose |
|-------|----------|---------|
| 1 | `playbooks/01-terraform-infra.yml` | VPC + builder EC2 (Path A) |
| 1b | `playbooks/01-terraform-infra-imagebuilder.yml` | VPC + Image Builder pipeline (Path B) |
| 1c | `playbooks/01-terraform-infra-packer.yml` | VPC only for Packer path (Path C) |
| 2 | `playbooks/02-golden-image.yml` | Golden AMI (`golden_image_method` var) |
| 3 | `playbooks/03-deploy-sap.yml` | SAP + Db2 EC2 from golden AMI |
| — | `playbooks/site.yml` | Full pipeline — Ansible golden image |
| — | `playbooks/site-imagebuilder.yml` | Full pipeline — EC2 Image Builder |
| — | `playbooks/site-packer.yml` | Full pipeline — Packer golden AMI |
| — | `playbooks/hcp-terraform-only.yml` | Terraform only (default `hashicorp.terraform`) |
| — | `playbooks/local-terraform-only.yml` | CLI + S3 fallback (`cloud.terraform`) |

## Bootstrap credentials from `.env` (optional)

To push AWS / HCP / SSH credentials and sync job-template `extra_vars` via API:

```bash
cp .env.aap.example .env.aap
source scripts/load-env-aap.sh
./scripts/bootstrap-aap.sh
```

See **[aap-bootstrap.md](aap-bootstrap.md)**.

## Credentials (AAP)

| Credential type | Used for |
|-----------------|----------|
| Amazon Web Services | EC2, AMI, instance terminate |
| Machine / SSH | Builder provisioning (key from `ssh_key_name`) |
| Custom: HCP Terraform API | `TF_TOKEN` / `hcp_terraform_token` when `terraform_driver: hcp` |

## Extra variables

```yaml
terraform_driver: hcp            # default; use local for cloud.terraform + S3
hcp_terraform_workspace_id: ws-xxx
golden_image_method: ansible     # or image_builder
image_builder_version: "1.0.0"   # bump to rebuild Image Builder recipe
golden_ami_id: ami-xxx           # required for playbook 03 if not running site.yml
```

## HCP Terraform credential (default)

Create a custom credential type or use env injection with field `TF_TOKEN` mapped to `hcp_terraform_token`. The workspace must have AWS credentials configured for runs (env vars or variable sets).

## EC2 Image Builder notes

- Execution environment needs **AWS CLI** for `imagebuilder start-image-pipeline-execution`.
- IAM: `imagebuilder:*`, `ec2:DescribeImages`, and pass-through for build instance role (created by Terraform module).
- Pipeline schedule is set to a far-future cron; builds are **on-demand** from AAP only.

## Survey example (phase 3)

- `golden_ami_id` (required)
- `deploy_sap_stack` (default true)
