# PPT story alignment — IBM Db2 + HCP (`hashicorp.terraform`)

This repository implements the slide narrative with **IBM Db2** (not SAP HANA) and **HCP Terraform** via the **`hashicorp.terraform`** collection.

## Day mapping

| PPT day | What it means here | AAP job template playbook |
|---------|-------------------|---------------------------|
| **Day 0** | Pre-flight → `hashicorp.terraform` apply → post-flight → **inventory sync** | `playbooks/day0-infrastructure.yml` |
| **Day 0** (deploy) | Apply golden AMI → SAP + Db2 EC2 | `playbooks/day0-deploy-workload.yml` |
| **Day 0.5** | Ansible golden image (PPT “Packer + Ansible provisioner”) | `playbooks/day05-golden-image.yml` |
| **Day 1** | OS prep → **Db2 install** → SWPM → validate | `playbooks/day1-install.yml` |
| **Day 2** | Start/stop, patch, backup, compliance (tagged stubs) | `playbooks/day2-operations.yml` |
| **Full run** | All phases in one job | `playbooks/site.yml` |

## AAP workflow job template (recommended)

Create a **Workflow Job Template** with four nodes:

```text
┌─────────────────────────┐
│ 1. Day 0 Infrastructure │  playbook: day0-infrastructure.yml
│    (pre/post + HCP TF)   │  credentials: AWS, HCP (TF_TOKEN), SSH
└───────────┬─────────────┘
            │ on success
┌───────────▼─────────────┐
│ 2. Day 0.5 Golden Image  │  playbook: day05-golden-image.yml
│    (Ansible → AMI)        │  credentials: AWS, SSH
└───────────┬─────────────┘
            │ on success — pass golden_ami_id via set_stats
┌───────────▼─────────────┐
│ 3. Day 0 Deploy Workload │  playbook: day0-deploy-workload.yml
│    (HCP TF + inventory)   │  survey/extra: golden_ami_id (from stats)
└───────────┬─────────────┘
            │ on success
┌───────────▼─────────────┐
│ 4. Day 1 Install         │  playbook: day1-install.yml
│    (IBM Db2 + SWPM)       │  inventory: synced hosts (bastion/SSM required for private IPs)
└─────────────────────────┘
```

Optional **approval** nodes between 1→2 and 3→4.

### Workflow variables

Use **workflow job template** extra vars or **survey** on node 3:

```yaml
golden_ami_id: "{{ stats.golden_ami_id }}"   # from Day 0.5 set_stats
```

AAP 2.x: enable **Artifacts** / copy `set_stats` from job 2 to job 3 (or use unified survey).

### Credentials (not in code)

| Credential | Injected as |
|------------|-------------|
| HCP Terraform API token | `TF_TOKEN` |
| Amazon Web Services | AWS modules |
| Machine / SSH | Builder + private hosts (via bastion if needed) |

Configure **AWS credentials on the HCP workspace** for Terraform runs.

## PPT slide → role mapping (Db2, not HANA)

| PPT | This repo |
|-----|-----------|
| `cloud.terraform.terraform` | **`hashicorp.terraform`** (default HCP); `cloud.terraform` = `terraform_driver: local` fallback |
| Pre-flight quotas/network | `roles/terraform_preflight` |
| Post-flight health | `roles/terraform_postflight` |
| Outputs → inventory | `roles/terraform_inventory` + `set_stats` |
| Rollback destroy | `roles/terraform_rollback` |
| Packer + Ansible provisioner | `golden_image` + `sap_general_preconfigure` / `sap_db2_preconfigure` |
| `sap_hana_preconfigure` | **`sap_db2_preconfigure`** → `db2_prep` |
| `sap_hana_install` / `hdblcm` | **`db2_install`** (IBM Db2 media) |
| HANA HSR | **Db2 HADR** — Day 2 `monitor` tag stub |
| S/4 SWPM | `sap_swpm_install` |
| Validate | `sap_validate` |
| Day 2 operations | `day2_sap_operations` |

## Day 1 enable real installs

Default is **placeholder** (debug only). To run real installs:

```yaml
db2_perform_install: true
db2_install_media_path: /path/to/db2/media
sap_perform_swpm: true
sap_swpm_inifile: /path/to/inifile.params
sap_swpm_media_path: /path/to/sap/media
```

## Private subnet note

SAP/Db2 EC2 are in **private subnets**. Day 1 jobs need **bastion**, **SSM Session Manager**, or **VPN** so Ansible can reach `tf_sap_private_ip` / `tf_db2_private_ip`.

## Full pipeline one job

```yaml
run_day0: true
run_day05: true
run_day0_deploy: true
run_day1: true   # set true to chain day1-install in site.yml
```

```bash
ansible-playbook playbooks/site.yml -e run_day1=true
```
