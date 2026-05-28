# AAP setup in ~30 minutes

Hands-on checklist for the SAP modernization PPT pipeline on **Ansible Automation Platform 2.x**. Assumes you already ran Day 0 locally once (or have AWS + HCP working).

**Total:** ~30 min (excluding long job runtimes).

---

## Before you start (5 min)

Have these ready:

| Item | Example |
|------|---------|
| AAP URL + admin (or org admin) login | `https://aap.example.com` |
| Git URL of this repo | `https://github.com/you/sap-modernization` |
| AWS access key + secret | Same as local `.env` |
| HCP Terraform token | `TF_TOKEN` |
| HCP org + workspace | `Ansible-BU-TFC` / `demo_test` |
| EC2 key pair name + `.pem` file | `demo_test`, `chmod 600` |
| AAP controller **egress IP** | For `allowed_ssh_cidr` (or use a /32 from your VPN) |
| Red Hat **Automation Hub** token | For EE build |

On HCP (2 min): Workspace → **Variables** → add **Environment** variables:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

(Terraform runs execute in HCP, not on the AAP controller.)

---

## Phase 1 — Execution environment (8 min)

1. **Automation Hub** → Collections → ensure these are synced/approved:
   - `hashicorp.terraform`
   - `amazon.aws`
   - `ansible.posix`
2. **Execution Environments** → **Create**
   - Name: `sap-mod-ee`
   - Image: start from `ansible-automation-platform-24/de-supported-rhel9` (or your platform default)
   - **Dependencies** (paste or use `requirements-aap.yml` from the repo):

     ```yaml
     ---
     collections:
       - name: hashicorp.terraform
         source: https://console.redhat.com/api/automation-hub/content/published/
       - name: amazon.aws
       - name: ansible.posix
     ```

   - Add **Python** packages in the EE definition (if your UI supports `bindep` / `pip`):

     ```
     boto3
     pytfe
     ```

3. **Build** the EE and wait until status is **Ready**.

---

## Phase 2 — API setup from laptop (~5 min)

While collections sync / EE build in the UI:

```bash
cp .env.aap.example .env.aap
# Fill: CONTROLLER_HOST, CONTROLLER_OAUTH_TOKEN, AAP_PROJECT_SCM_URL, AAP_EXECUTION_ENVIRONMENT

ansible-galaxy collection install -r requirements-aap-bootstrap.yml -p ./collections
source scripts/load-env-aap.sh
./scripts/setup-aap.sh
```

This creates **project**, **inventory**, **credentials**, **job templates**, and **workflow**. See [aap-bootstrap.md](aap-bootstrap.md).

Skip UI Phases 3–5 below if the playbook succeeds.

---

## Phase 2b — Manual UI (only if API setup not used)

### Project + inventory

Create project `SAP Modernization`, inventory `SAP Mod Localhost`, host `localhost` with `ansible_connection: local`.

### Credentials + job templates + workflow

See prior tables in [aap-job-templates.md](aap-job-templates.md) or run `./scripts/setup-aap.sh`.

---

## Phase 3 — First run (launch and verify)

1. Launch **workflow** (not a single job).
2. **Day 0** (~10–20 min): HCP apply + postflight SSH to builder.
   - If SSH postflight fails: fix `allowed_ssh_cidr` to controller egress IP, re-run Day 0 only.
3. **Day 0.5** (~20–45 min): Provision builder + `ec2_ami` golden image.
   - Confirm job stats / artifacts show `golden_ami_id`.
4. **Day 0 Deploy** (~10–20 min): HCP apply with `golden_ami_id`.
5. **Day 1** — skip unless bastion/SSM to private SAP/Db2 hosts is configured.

---

## Quick troubleshooting

| Symptom | Fix |
|---------|-----|
| `CERTIFICATE_VERIFY_FAILED` on setup | Set `AAP_VERIFY_SSL=false` in `.env.aap` (IP/self-signed TLS); re-run `./scripts/setup-aap.sh` |
| Terminal closes after `source load-env-aap.sh` | Do not use `set -e` in your shell before sourcing; script no longer enables it |
| Project sync `401` on Automation Hub | Configure Hub credential on the controller, then sync project manually |
| `hashicorp.terraform` missing | EE built from Hub; sync `requirements-aap.yml` |
| HCP variable validation failed | Extra vars need quoted strings — use bootstrap or copy from `group_vars/demo/aws.yml` |
| Builder SSH timeout on Day 0 | `allowed_ssh_cidr` = AAP egress /32 |
| Day 0.5 `Permission denied (publickey)` | Machine credential + `ec2-user` + `chmod 600` on `.pem` |
| Day 0.5 module interpreter error | Do not set global `ANSIBLE_PYTHON_INTERPRETER` on EE for remote hosts |
| Deploy missing `golden_ami_id` | Workflow artifact / survey from node 2 |
| Terraform fails in HCP | AWS vars on **workspace**, not only on AAP |

---

## Related docs

- [aap-bootstrap.md](aap-bootstrap.md) — API upload of credentials
- [ppt-story-and-aap-workflow.md](ppt-story-and-aap-workflow.md) — PPT mapping
- [aap-job-templates.md](aap-job-templates.md) — reference tables
- [hcp-terraform-setup.md](hcp-terraform-setup.md) — workspace variables
