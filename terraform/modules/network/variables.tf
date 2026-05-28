variable "name_prefix" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed SSH access to builder security group"
  type        = string
  default     = "0.0.0.0/0"
}
