output "image_pipeline_arn" {
  value = aws_imagebuilder_image_pipeline.golden.arn
}

output "image_pipeline_name" {
  value = aws_imagebuilder_image_pipeline.golden.name
}

output "image_recipe_arn" {
  value = aws_imagebuilder_image_recipe.golden.arn
}

output "component_arn" {
  value = aws_imagebuilder_component.sap_db2_prep.arn
}

output "infrastructure_configuration_arn" {
  value = aws_imagebuilder_infrastructure_configuration.build.arn
}

output "distribution_configuration_arn" {
  value = aws_imagebuilder_distribution_configuration.golden.arn
}
