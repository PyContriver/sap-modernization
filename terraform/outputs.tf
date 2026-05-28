output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "builder_instance_id" {
  description = "Ephemeral EC2 used by Ansible golden-image role (Packer replacement)"
  value       = try(module.builder[0].instance_id, null)
}

output "builder_public_ip" {
  value = try(module.builder[0].public_ip, null)
}

output "builder_private_ip" {
  value = try(module.builder[0].private_ip, null)
}

output "sap_instance_id" {
  value = try(module.sap_workload[0].sap_instance_id, null)
}

output "db2_instance_id" {
  value = try(module.sap_workload[0].db2_instance_id, null)
}

output "sap_private_ip" {
  value = try(module.sap_workload[0].sap_private_ip, null)
}

output "db2_private_ip" {
  value = try(module.sap_workload[0].db2_private_ip, null)
}

output "golden_ami_id_in_use" {
  value = local.sap_ami_id
}

output "image_pipeline_arn" {
  description = "EC2 Image Builder pipeline ARN (golden_image_method=image_builder)"
  value       = try(module.image_builder[0].image_pipeline_arn, null)
}

output "image_pipeline_name" {
  value = try(module.image_builder[0].image_pipeline_name, null)
}

output "image_recipe_arn" {
  value = try(module.image_builder[0].image_recipe_arn, null)
}
