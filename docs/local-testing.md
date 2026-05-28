# Local testing

## Collection install error (`hashicorp.terraform` not found)

`hashicorp.terraform` is a **Red Hat certified** collection on **Automation Hub**, not on [galaxy.ansible.com](https://galaxy.ansible.com).

| Environment | Requirements file | Terraform driver |
|-------------|-------------------|------------------|
| **Default (AH token)** | `requirements.yml` | `hcp` (`hashicorp.terraform`) |
| **No Hub access** | `requirements-local.yml` | `local` (`cloud.terraform`) |

### Local install (fixes Galaxy error)

```bash
ansible-galaxy collection install -r requirements-local.yml
```

Run playbooks with:

```yaml
# Extra var or in group_vars/all.yml for local only
terraform_driver: local
```

Bootstrap S3 state (local driver only):

```bash
./scripts/bootstrap-tf-state.sh
cp terraform/backend.tf.example terraform/backend.tf
```

### Certified `hashicorp.terraform` locally (Automation Hub)

You **can** use the certified collection on your laptop if you have Hub access. Full steps: **[automation-hub-local-install.md](automation-hub-local-install.md)**.

```bash
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN='...'   # from console.redhat.com
# Merge [galaxy] section from ansible.cfg.automation-hub.example into ansible.cfg
ansible-galaxy collection install -r requirements-aap.yml
export TF_TOKEN='...'
ansible-playbook playbooks/day0-infrastructure.yml -e terraform_driver=hcp
```

## Builder SSH CIDR (`ALLOWED_SSH_CIDR`)

Terraform opens builder port 22 only to `allowed_ssh_cidr`. The example `203.0.113.0/32` is **not** your IP — SSH postflight will time out.

`source scripts/load-env.sh` auto-detects your public IP when `.env` still has the example value. After changing CIDR, **re-run Day 0** so HCP/Terraform updates the security group. Post-flight failures do **not** trigger auto-destroy (only a failed Terraform apply does).

## Base AMI (not required to create one)

You do **not** need a custom golden AMI to start. Leave `BASE_AMI_ID` unset in `.env`; Day 0 preflight resolves the latest **RHEL 9** HVM AMI from Red Hat (`309956199498`) in `AWS_DEFAULT_REGION`. Day 0.5 builds your **golden AMI** from that base.

**Prerequisite:** your AWS account must be subscribed to **Red Hat Enterprise Linux** on [AWS Marketplace](https://aws.amazon.com/marketplace/pp/prodview-2q5vk6wlpo6wq) (free to subscribe; usage is billed per Red Hat terms).

Set `BASE_AMI_ID` to pin a specific AMI, or change `base_ami_name_filter` in `group_vars/demo/aws.yml` (e.g. `RHEL-8.*_HVM*x86_64*` for RHEL 8).

## Python deps (`boto3` / `botocore`)

Local playbooks need Python libs on the interpreter Ansible uses (Homebrew Python often lacks them):

| Package | Used by |
|---------|---------|
| `boto3` / `botocore` | `amazon.aws` preflight, golden AMI |
| `pytfe` | `hashicorp.terraform` (HCP upload/run) |

```bash
./scripts/setup-local-venv.sh
source scripts/load-env.sh   # sets sap_mod_local_python for localhost only (not remote EC2)
```

## Environment file (recommended)

```bash
cp .env.example .env
# Edit .env with AH token, TF_TOKEN, AWS keys, ssh_key_name (BASE_AMI_ID optional)

source scripts/load-env.sh
ansible-playbook playbooks/day0-infrastructure.yml -e "@${SAP_MOD_EXTRA_VARS_FILE}"
```

Or: `./scripts/run-day0.sh`

## EC2 SSH private key (Day 0.5 / Day 1)

Ansible must SSH to the builder as `ec2-user` using the key pair named in `SSH_KEY_NAME`. Set in `.env`:

```bash
SSH_PRIVATE_KEY_FILE=~/.ssh/demo_test.pem
chmod 600 ~/.ssh/demo_test.pem
```

`load-env.sh` auto-detects `~/.ssh/${SSH_KEY_NAME}.pem` when unset.

## Day 0.5 after Day 0 (separate playbook)

Day 0.5 needs `tf_builder_instance_id` from Day 0. The `terraform_load_outputs` role loads them from (in order):

1. `inventory/generated/terraform_outputs.yml` (written at end of Day 0)
2. `inventory/generated/hosts.yml` (builder host key = instance id)
3. HCP workspace API (needs `TF_TOKEN` + org/workspace in `.env`)

```bash
source scripts/load-env.sh
./scripts/run-day05.sh
```

## Phased local test

```bash
source scripts/load-env.sh
# Or export AWS_* / TF_TOKEN manually

# Local driver (no TF_TOKEN required)
ansible-playbook playbooks/day0-infrastructure.yml -e terraform_driver=local

ansible-playbook playbooks/day05-golden-image.yml -e terraform_driver=local
ansible-playbook playbooks/day0-deploy-workload.yml -e terraform_driver=local -e golden_ami_id=ami-xxx
```

With HCP (needs Hub collection + token):

```bash
export TF_TOKEN=...
ansible-galaxy collection install -r requirements-aap.yml
ansible-playbook playbooks/day0-infrastructure.yml -e terraform_driver=hcp
```

## Syntax only (no cloud)

```bash
ansible-galaxy collection install -r requirements-local.yml
for pb in playbooks/day*.yml playbooks/site.yml; do ansible-playbook "$pb" --syntax-check; done
```
