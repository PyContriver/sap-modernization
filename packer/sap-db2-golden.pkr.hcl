# Golden AMI build — same SAP + IBM Db2 prep as Ansible/Image Builder paths.
# License: Packer binary is HashiCorp BSL; for fully OSS demos use golden_image_method: ansible
# See docs/opensource-golden-images.md

packer {
  required_version = ">= 1.9.0"
  required_plugins {
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "source_ami" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "m5.xlarge"
}

variable "ssh_username" {
  type    = string
  default = "ec2-user"
}

variable "ami_name_prefix" {
  type    = string
  default = "sap-mod-demo-sap-db2"
}

variable "subnet_id" {
  type    = string
  default = ""
}

variable "environment" {
  type    = string
  default = "demo"
}

variable "sap_sid" {
  type    = string
  default = "DEV"
}

variable "db2_instance_name" {
  type    = string
  default = "db2inst1"
}

locals {
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
  ami_name  = "${var.ami_name_prefix}-${local.timestamp}"
}

source "amazon-ebs" "golden" {
  ami_name      = local.ami_name
  instance_type = var.instance_type
  region        = var.region
  source_ami    = var.source_ami
  ssh_username  = var.ssh_username
  subnet_id     = var.subnet_id != "" ? var.subnet_id : null

  tags = {
    Name        = local.ami_name
    GoldenImage = "true"
    Workload    = "sap"
    Database    = "ibm_db2"
    BuiltBy     = "packer"
    Environment = var.environment
    SapSid      = var.sap_sid
  }

  run_tags = {
    Role = "packer-golden-builder"
  }
}

build {
  sources = ["source.amazon-ebs.golden"]

  provisioner "ansible" {
    playbook_file = "${path.root}/ansible/packer-playbook.yml"
    extra_arguments = [
      "-e", "sap_sid=${var.sap_sid}",
      "-e", "db2_instance_name=${var.db2_instance_name}",
      "--roles-path", "${path.root}/../roles",
    ]
    user = var.ssh_username
  }

  post-processor "manifest" {
    output     = "${path.root}/manifest.json"
    strip_path = true
  }
}
