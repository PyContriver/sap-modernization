output "sap_instance_id" {
  value = aws_instance.sap.id
}

output "db2_instance_id" {
  value = aws_instance.db2.id
}

output "sap_private_ip" {
  value = aws_instance.sap.private_ip
}

output "db2_private_ip" {
  value = aws_instance.db2.private_ip
}
