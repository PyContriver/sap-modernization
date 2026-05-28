output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "builder_security_group_id" {
  value = aws_security_group.builder.id
}

output "sap_security_group_id" {
  value = aws_security_group.sap.id
}

output "db2_security_group_id" {
  value = aws_security_group.db2.id
}
