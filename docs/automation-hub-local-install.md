# Use certified `hashicorp.terraform` on your laptop

The collection is **certified on Red Hat Automation Hub**. You can install and run it locally the same way AAP does, as long as you have **Automation Hub access** (Ansible subscription / partner / trial that includes Hub).

You do **not** need a running AAP controller — only a Hub API token and HCP Terraform (`TF_TOKEN`).

## 1. Prerequisites

| Requirement | Purpose |
|-------------|---------|
| Red Hat account with **Automation Hub** access | Download certified collections |
| **HCP Terraform** org + workspace | Remote state + runs |
| **HCP API token** | `export TF_TOKEN=...` |
| **AWS credentials** on the HCP workspace | Terraform creates VPC/EC2 |
| **AWS credentials** on your shell | `amazon.aws` for AMI/EC2 modules |
| Ansible 2.14+ recommended | `pip install ansible` or `dnf install ansible-core` |

## 2. Secrets via `.env` (recommended)

```bash
cp .env.example .env
# Edit .env — set ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN, TF_TOKEN, AWS_*, BASE_AMI_ID, etc.
source scripts/load-env.sh
```

**Do not commit `.env`** (already in `.gitignore`).

Automation Hub token: https://console.redhat.com/ansible/automation-hub/token

## 3. Configure `ansible-galaxy` to use Automation Hub

### Option A — Environment variable (recommended)

Append the `[galaxy]` block from `ansible.cfg.automation-hub.example` to your project `ansible.cfg`, but **omit** the `token =` line and use:

```bash
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN='your-hub-token-here'
```

Ansible 2.15+ maps this to the `automation_hub` server entry when configured in `ansible.cfg`.

### Option B — Token in user config (not in repo)

Put the full `[galaxy]` + `[galaxy_server.automation_hub]` section in `~/.ansible.cfg` with your token.

### Option C — Merge into project `ansible.cfg` (local only, gitignored)

```bash
cat ansible.cfg.automation-hub.example >> ansible.cfg
# Edit ansible.cfg and set token locally — never commit
```

Add `ansible.cfg` to personal git exclude if you embed the token (better: use Option A).

**Merged `ansible.cfg` should include:**

```ini
[galaxy]
server_list = automation_hub, release_galaxy

[galaxy_server.automation_hub]
url = https://console.redhat.com/api/automation-hub/content/published/
auth_url = https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token

[galaxy_server.release_galaxy]
url = https://galaxy.ansible.com/
ignore_errors = true
```

## 4. Install collections

```bash
cd /path/to/sap-modernization
ansible-galaxy collection install -r requirements-aap.yml -p ./collections
```

Or install to user path (default):

```bash
ansible-galaxy collection install -r requirements-aap.yml
```

Verify:

```bash
ansible-galaxy collection list | grep hashicorp.terraform
```

## 5. Point Ansible at installed collections (if using `-p ./collections`)

```ini
# ansible.cfg
collections_paths = ./collections
```

Or export:

```bash
export ANSIBLE_COLLECTIONS_PATH="$(pwd)/collections"
```

## 6. Configure HCP + project vars

**`group_vars/all.yml`:**

```yaml
terraform_driver: hcp
hcp_terraform_organization: YOUR-ORG
hcp_terraform_workspace: sap-modernization-demo
# hcp_terraform_workspace_id: ws-xxxxxxxx
```

**`group_vars/demo/aws.yml`:** `base_ami_id`, `ssh_key_name`, `allowed_ssh_cidr`

**Shell:**

```bash
export TF_TOKEN='your-hcp-terraform-api-token'
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=us-east-1
```

On the **HCP workspace**, set AWS credentials for Terraform runs (variable set or env vars on the workspace).

## 7. Run playbooks locally (same as AAP)

```bash
ansible-playbook playbooks/day0-infrastructure.yml -e terraform_driver=hcp
ansible-playbook playbooks/day05-golden-image.yml -e terraform_driver=hcp
ansible-playbook playbooks/day0-deploy-workload.yml -e terraform_driver=hcp -e golden_ami_id=ami-xxxxxxxx
```

## Troubleshooting

| Error | Fix |
|-------|-----|
| `hashicorp.terraform` not found | Hub token missing/wrong; `server_list` not in `ansible.cfg` |
| 401 from Automation Hub | Refresh Hub token; check subscription |
| HCP auth failed | `TF_TOKEN` scope must include target org/workspace |
| Terraform run fails in HCP | Add AWS creds to **workspace**, not only your laptop |
| Collection install still uses only Galaxy | `server_list` must list `automation_hub` **first** |

## Without Automation Hub access

Use community collections only:

```bash
ansible-galaxy collection install -r requirements-local.yml
ansible-playbook ... -e terraform_driver=local
```

That uses `cloud.terraform` (CLI + S3), not the certified HCP API collection.
