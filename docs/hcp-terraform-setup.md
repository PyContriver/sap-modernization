# HCP Terraform / TFE setup (default driver)

## Workspace

1. Create organization and workspace (VCS-driven or CLI/API uploads).
2. Set **Terraform variables** in the workspace for secrets, or pass via Ansible `terraform_variables` / `hcp_terraform_run_variables`.
3. Configure **AWS credentials** on the workspace (recommended: AWS dynamic credentials or `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` env vars on the workspace).

## Ansible / AAP

```yaml
# group_vars/all.yml
terraform_driver: hcp
hcp_terraform_organization: my-org
hcp_terraform_workspace: sap-modernization-demo
# hcp_terraform_workspace_id: ws-xxxxxxxx   # optional, preferred
```

AAP custom credential injects `TF_TOKEN` (team token with workspace access).

## State

State is stored in the workspace automatically. Do not commit `terraform.tfstate`. Avoid adding `backend.tf` (S3) to the config uploaded to HCP unless you intentionally use a remote S3 backend in the workspace.

## Outputs for golden image

After each apply, `roles/terraform_infra/tasks/hcp_outputs.yml` reads workspace outputs and sets:

- `tf_builder_instance_id`, `tf_builder_public_ip` (Ansible golden path)
- `tf_image_pipeline_arn` (Image Builder path)

Ensure `terraform/outputs.tf` values are exposed in the workspace run.

## CLI fallback

```bash
ansible-playbook playbooks/local-terraform-only.yml
```

Requires `terraform_driver: local`, S3 bootstrap, and `cloud.terraform` collection.
