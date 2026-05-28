resource "aws_instance" "builder" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euxo pipefail
    dnf -y update || yum -y update || true
    dnf -y install python3 python3-pip || yum -y install python3
    echo "sap-golden-image-builder-ready" > /etc/sap-builder-ready
  EOF
  )

  tags = {
    Name = "${var.name_prefix}-golden-builder"
    Role = "golden-image-builder"
  }
}
