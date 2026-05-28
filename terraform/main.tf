provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      {
        Project     = var.project_name
        Environment = var.environment
        ManagedBy   = "terraform"
        Workload    = "sap-modernization"
      },
      var.additional_tags
    )
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  sap_ami_id  = var.golden_ami_id != "" ? var.golden_ami_id : var.base_ami_id
}

module "network" {
  source = "./modules/network"

  name_prefix      = local.name_prefix
  vpc_cidr         = var.vpc_cidr
  aws_region       = var.aws_region
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

module "image_builder" {
  count  = var.deploy_image_builder ? 1 : 0
  source = "./modules/image_builder"

  name_prefix       = local.name_prefix
  base_ami_id       = var.base_ami_id
  aws_region        = var.aws_region
  vpc_id            = module.network.vpc_id
  subnet_id         = module.network.public_subnet_ids[0]
  instance_types    = var.image_builder_instance_types
  sap_sid           = var.sap_sid
  db2_instance_name = var.db2_instance_name
  db2_port          = var.db2_port
  image_version     = var.image_builder_version
}

module "builder" {
  count  = var.deploy_builder ? 1 : 0
  source = "./modules/builder"

  name_prefix       = local.name_prefix
  vpc_id            = module.network.vpc_id
  subnet_id         = module.network.public_subnet_ids[0]
  ami_id            = var.base_ami_id
  instance_type     = var.instance_type_builder
  ssh_key_name      = var.ssh_key_name
  allowed_ssh_cidr  = var.allowed_ssh_cidr
  security_group_id = module.network.builder_security_group_id
}

module "sap_workload" {
  count  = var.deploy_sap_stack ? 1 : 0
  source = "./modules/sap_workload"

  name_prefix        = local.name_prefix
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  ami_id             = local.sap_ami_id
  sap_instance_type  = var.instance_type_sap
  db2_instance_type  = var.instance_type_db2
  ssh_key_name       = var.ssh_key_name
  sap_security_group = module.network.sap_security_group_id
  db2_security_group = module.network.db2_security_group_id
  sap_sid            = var.sap_sid
  db2_instance_name  = var.db2_instance_name
}
