output "instance_id" {
  value = aws_instance.builder.id
}

output "public_ip" {
  value = aws_instance.builder.public_ip
}

output "private_ip" {
  value = aws_instance.builder.private_ip
}
