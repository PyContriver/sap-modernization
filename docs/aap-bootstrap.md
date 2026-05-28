# Bootstrap AAP credentials and variables from `.env`

Use this when you have **admin API access** to Ansible Automation Platform and want to upload the same secrets you use locally (`AWS_*`, `TF_TOKEN`, SSH private key) into Controller **credentials**, plus sync **job template extra vars**.

This does **not** replace manual setup of **Project**, **Execution Environment**, **Inventory**, or **Job Templates** — create those once in the UI (or extend the bootstrap playbook later). The bootstrap playbook **updates** job templates **if they already exist** with the names in `group_vars/aap_bootstrap.yml`.

## Prerequisites

| Item | Notes |
|------|--------|
| AAP 2.x with API access | User with permission to create credentials in your org |
| `.env` | `AWS_*`, `TF_TOKEN`, `SSH_KEY_NAME`, `SSH_PRIVATE_KEY_FILE`, HCP org/workspace |
| `.env.aap` | `CONTROLLER_HOST`, `CONTROLLER_OAUTH_TOKEN` |
| Collection | `ansible.controller` — `requirements-aap-bootstrap.yml` |

## Quick start

```bash
cp .env.aap.example .env.aap
# Edit .env.aap — CONTROLLER_HOST, CONTROLLER_OAUTH_TOKEN

ansible-galaxy collection install -r requirements-aap-bootstrap.yml -p ./collections

source scripts/load-env-aap.sh
./scripts/bootstrap-aap.sh
```

## What gets created in AAP

| Object | Name (default) | Source |
|--------|----------------|--------|
| Credential type | `HCP Terraform API` | Custom — injects `TF_TOKEN` env |
| Credential | `SAP Mod - AWS` | `.env` `AWS_ACCESS_KEY_ID` / `SECRET` |
| Credential | `SAP Mod - HCP Terraform` | `.env` `TF_TOKEN` |
| Credential | `SAP Mod - Builder SSH` | `SSH_PRIVATE_KEY_FILE`, user `ec2-user` |
| Job template `extra_vars` | Templates listed in `aap_job_template_names` | `group_vars` + demo/aws vars |

## Controller API token

AAP → **Access** → **Users** → your user → **Tokens** → Create token.

Set in `.env.aap`:

```bash
CONTROLLER_HOST=https://aap.example.com
CONTROLLER_OAUTH_TOKEN=your-oauth-token
AAP_ORGANIZATION=Default
```

Alternative: `CONTROLLER_USERNAME` + `CONTROLLER_PASSWORD` (basic auth).

## Attach credentials to job templates (UI)

After bootstrap, edit each job template in AAP:

| Job template | Credentials |
|--------------|-------------|
| Day 0 Infrastructure | AWS + HCP Terraform |
| Day 0.5 Golden Image | AWS + Builder SSH |
| Day 0 Deploy Workload | AWS + HCP Terraform |
| Day 1 Install | AWS + Builder SSH (or bastion) |

Workflow: [ppt-story-and-aap-workflow.md](ppt-story-and-aap-workflow.md)

## Job template names

Defaults in `group_vars/aap_bootstrap.yml`:

- `SAP Mod - Day 0 Infrastructure`
- `SAP Mod - Day 0.5 Golden Image`
- `SAP Mod - Day 0 Deploy Workload`
- `SAP Mod - Day 1 Install`

Rename in that file to match your AAP job templates, or set `aap_sync_job_template_extra_vars: false` to only upload credentials.

## HCP workspace AWS credentials

Bootstrap uploads **controller-side** AWS and **TF_TOKEN** only. Terraform runs in HCP still need **AWS on the workspace** (variable set or env) — see [hcp-terraform-setup.md](hcp-terraform-setup.md).

## Security

- Never commit `.env` or `.env.aap`
- Bootstrap runs with `no_log` on credential modules
- Rotate tokens if `.env.aap` was exposed
