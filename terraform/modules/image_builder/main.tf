data "aws_ami" "parent" {
  owners = ["self", "amazon"]

  filter {
    name   = "image-id"
    values = [var.base_ami_id]
  }
}

data "aws_region" "current" {}

# IAM role for Image Builder build instances
resource "aws_iam_role" "imagebuilder" {
  name = "${var.name_prefix}-imagebuilder"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "imagebuilder_ssm" {
  role       = aws_iam_role.imagebuilder.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "imagebuilder_ec2_profile" {
  role       = aws_iam_role.imagebuilder.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

resource "aws_security_group" "build" {
  name        = "${var.name_prefix}-imagebuilder-build"
  description = "Image Builder ephemeral build instances"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-imagebuilder-build-sg"
  }
}

resource "aws_iam_instance_profile" "imagebuilder" {
  name = "${var.name_prefix}-imagebuilder"
  role = aws_iam_role.imagebuilder.name
}

# Custom build component — mirrors sap_os_prep + db2_prep (shell, no Ansible EE required on builder)
resource "aws_imagebuilder_component" "sap_db2_prep" {
  name     = "${var.name_prefix}-sap-db2-prep"
  platform = "Linux"
  version  = var.image_version
  data = yamlencode({
    name          = "SAP Db2 Golden Image Prep"
    description   = "Demo SAP OS layout and IBM Db2 prerequisites (not full Db2 install)"
    schemaVersion = 1.0
    phases = [{
      name = "build"
      steps = [{
        name   = "SapOsAndDb2Prep"
        action = "ExecuteBash"
        inputs = {
          commands = [
            "set -euxo pipefail",
            "dnf -y install python3 unzip tar libaio numactl ksh || yum -y install python3 unzip tar libaio numactl ksh || true",
            "mkdir -p /sapmnt /usr/sap /db2",
            "groupadd -f dba && groupadd -f db2iadm1 && groupadd -f db2grp1 || true",
            "id ${var.db2_instance_name} &>/dev/null || useradd -m -g db2grp1 -G dba,db2iadm1 ${var.db2_instance_name} || true",
            "mkdir -p /db2/${var.db2_instance_name}/{NODE0000,LOGDIR,ARCHIVE}",
            "chown -R ${var.db2_instance_name}:db2grp1 /db2/${var.db2_instance_name} || true",
            "echo 'sap_sid=${var.sap_sid}' > /etc/sap-golden-image-metadata",
            "echo 'db2_instance=${var.db2_instance_name}' >> /etc/sap-golden-image-metadata",
            "echo 'db2_port=${var.db2_port}' >> /etc/sap-golden-image-metadata",
            "echo 'database=ibm_db2' >> /etc/sap-golden-image-metadata",
            "echo 'built_by=ec2-image-builder' >> /etc/sap-golden-image-metadata",
            "touch /etc/sap-os-ready /etc/db2-prep-ready",
          ]
        }
      }]
    }]
  })
}

resource "aws_imagebuilder_image_recipe" "golden" {
  name         = "${var.name_prefix}-golden-recipe"
  version      = var.image_version
  parent_image = var.base_ami_id

  block_device_mapping {
    device_name = data.aws_ami.parent.root_device_name
    ebs {
      volume_size           = 100
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  component {
    component_arn = aws_imagebuilder_component.sap_db2_prep.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_imagebuilder_infrastructure_configuration" "build" {
  name                          = "${var.name_prefix}-imagebuilder-infra"
  instance_profile_name         = aws_iam_instance_profile.imagebuilder.name
  instance_types                = var.instance_types
  subnet_id                     = var.subnet_id
  terminate_instance_on_failure = true

  security_group_ids = [aws_security_group.build.id]
}

resource "aws_imagebuilder_distribution_configuration" "golden" {
  name = "${var.name_prefix}-golden-distribution"

  distribution {
    region = data.aws_region.current.name

    ami_distribution_configuration {
      name = "${var.name_prefix}-golden-{{ imagebuilder:buildDate }}"

      ami_tags = {
        Name        = "${var.name_prefix}-golden"
        GoldenImage = "true"
        Workload    = "sap"
        Database    = "ibm_db2"
        BuiltBy     = "ec2-image-builder"
        SapSid      = var.sap_sid
      }
    }
  }
}

resource "aws_imagebuilder_image_pipeline" "golden" {
  name                             = "${var.name_prefix}-golden-pipeline"
  image_recipe_arn                 = aws_imagebuilder_image_recipe.golden.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.build.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.golden.arn

  image_tests_configuration {
    image_tests_enabled = false
  }

  schedule {
    schedule_expression                = "cron(0 0 1 1 ? 2099)"
    pipeline_execution_start_condition = "EXPRESSION_MATCH_ONLY"
  }

  status = "ENABLED"
}
