resource "aws_instance" "db2" {
  ami                    = var.ami_id
  instance_type          = var.db2_instance_type
  subnet_id              = var.private_subnet_ids[0]
  vpc_security_group_ids = [var.db2_security_group]
  key_name               = var.ssh_key_name

  root_block_device {
    volume_size = 200
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.name_prefix}-db2"
    Role        = "ibm-db2"
    Db2Instance = var.db2_instance_name
    SapSid      = var.sap_sid
  }
}

resource "aws_instance" "sap" {
  ami                    = var.ami_id
  instance_type          = var.sap_instance_type
  subnet_id              = var.private_subnet_ids[1]
  vpc_security_group_ids = [var.sap_security_group]
  key_name               = var.ssh_key_name

  depends_on = [aws_instance.db2]

  root_block_device {
    volume_size = 150
    volume_type = "gp3"
  }

  tags = {
    Name    = "${var.name_prefix}-sap-app"
    Role    = "sap-application"
    SapSid  = var.sap_sid
    Db2Host = aws_instance.db2.private_ip
  }
}
