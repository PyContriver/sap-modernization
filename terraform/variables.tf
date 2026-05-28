variable "aws_region" {
  description = "AWS region for SAP modernization demo"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment label (demo, dev, prod)"
  type        = string
  default     = "demo"
}

variable "project_name" {
  description = "Prefix for resource names and tags"
  type        = string
  default     = "sap-mod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.40.0.0/16"
}

variable "base_ami_id" {
  description = "Marketplace or custom RHEL/SLES AMI used for image builder and SAP hosts"
  type        = string
}

variable "golden_ami_id" {
  description = "AMI produced by golden-image playbook; empty until image build completes"
  type        = string
  default     = ""
}

variable "instance_type_builder" {
  type    = string
  default = "m5.xlarge"
}

variable "instance_type_sap" {
  description = "SAP app server instance type (DB2 co-located demo)"
  type        = string
  default     = "m5.2xlarge"
}

variable "instance_type_db2" {
  description = "IBM Db2 database host"
  type        = string
  default     = "m5.2xlarge"
}

variable "deploy_builder" {
  description = "When true, Terraform creates the ephemeral golden-image builder EC2 (Ansible AMI path)"
  type        = bool
  default     = true
}

variable "deploy_image_builder" {
  description = "When true, Terraform creates EC2 Image Builder pipeline (image_builder golden path)"
  type        = bool
  default     = false
}

variable "image_builder_version" {
  description = "Image recipe/component version; bump to rebuild golden AMI"
  type        = string
  default     = "1.0.0"
}

variable "image_builder_instance_types" {
  type    = list(string)
  default = ["m5.xlarge"]
}

variable "db2_port" {
  type    = number
  default = 50000
}

variable "deploy_sap_stack" {
  description = "When true, Terraform creates SAP + Db2 EC2 instances"
  type        = bool
  default     = false
}

variable "ssh_key_name" {
  description = "EC2 key pair name for builder and workload SSH"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH to builder (restrict in production)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "sap_sid" {
  description = "SAP system ID (demo placeholder)"
  type        = string
  default     = "DEV"
}

variable "db2_instance_name" {
  description = "Db2 instance name"
  type        = string
  default     = "db2inst1"
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}
