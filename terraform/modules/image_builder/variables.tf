variable "name_prefix" {
  type = string
}

variable "base_ami_id" {
  description = "Parent AMI for the image recipe"
  type        = string
}

variable "aws_region" {
  type = string
}

variable "subnet_id" {
  description = "Subnet for Image Builder build instances"
  type        = string
}

variable "instance_types" {
  type    = list(string)
  default = ["m5.xlarge"]
}

variable "sap_sid" {
  type = string
}

variable "db2_instance_name" {
  type = string
}

variable "db2_port" {
  type    = number
  default = 50000
}

variable "image_version" {
  description = "Semantic version tag for recipe/component (e.g. 1.0.0)"
  type        = string
  default     = "1.0.0"
}

variable "vpc_id" {
  description = "VPC for Image Builder build security group"
  type        = string
}
