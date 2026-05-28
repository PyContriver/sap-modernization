# Golden image paths

See also [opensource-golden-images.md](opensource-golden-images.md) for OSS vs Packer (BSL) guidance.

## Comparison

| | **Ansible** (`ansible`) | **Image Builder** (`image_builder`) | **Packer** (`packer`) |
|---|-------------------------|-----------------------------------|------------------------|
| OSS-friendly | Yes | Yes (AWS) | Packer binary is BSL |
| Build host | Terraform builder EC2 | AWS-managed instance | Packer-launched EC2 |
| Config tool | Ansible roles | Bash component | Ansible provisioner → same roles |
| Snapshot | `ec2_ami` | Image Builder → AMI | `amazon-ebs` builder |
| Terraform flags | `deploy_builder=true` | `deploy_image_builder=true` | network only |
| Templates | — | `terraform/modules/image_builder` | `packer/sap-db2-golden.pkr.hcl` |

## Image Builder component

The Terraform module embeds a build component equivalent to `sap_os_prep` + `db2_prep`:

- SAP mount points (`/sapmnt`, `/usr/sap`, `/db2`)
- Db2 instance user and directories
- Metadata file `/etc/sap-golden-image-metadata`

To run **real Ansible** inside Image Builder later, add an SSM document or component that pulls your playbook tarball from S3 and invoke `ansible-playbook` (see [AWS for SAP golden AMI blog](https://aws.amazon.com/blogs/awsforsap/build-sap-golden-amis-with-ec2-image-builder-and-ansible/)).

## Rebuild

- **Ansible path**: re-run `02-golden-image.yml` (new AMI name with timestamp).
- **Image Builder path**: increment `image_builder_version` (recipe version must change), then re-run phase 2.
- **Packer path**: re-run `02-golden-image.yml -e golden_image_method=packer` or `playbooks/site-packer.yml`.

## Packer quick start

```bash
ansible-playbook playbooks/site-packer.yml
```

Requires `packer` on the controller/EE (`packer init` once under `packer/`).
