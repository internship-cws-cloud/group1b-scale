data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Obtain the latest Amazon Linux 2023 x86_64 AMI.
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# EC2 security group.
# No inbound access is required because we use SSM.
resource "aws_security_group" "runner" {
  name        = "group1b-k6-runner-sg"
  description = "Security group for temporary k6 load generator"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "group1b-k6-runner-sg"
    Purpose   = "Temporary performance testing"
    ManagedBy = "Terraform"
  }
}

# IAM trust policy.
resource "aws_iam_role" "runner" {
  name = "group1b-k6-runner-role"

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

# Allows the EC2 machine to register with AWS Systems Manager.
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "runner" {
  name = "group1b-k6-runner-profile"
  role = aws_iam_role.runner.name
}

resource "aws_instance" "runner" {
  ami           = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type

  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.runner.id
  ]

  iam_instance_profile = aws_iam_instance_profile.runner.name

  # Install k6 and prepare the test script.
  user_data = <<-EOF
    #!/bin/bash

    set -euxo pipefail

    dnf install -y https://dl.k6.io/rpm/repo.rpm
    dnf install -y k6

    mkdir -p /opt/loadtest

    cat > /opt/loadtest/experiment.js <<'K6SCRIPT'
    ${file("${path.module}/experiment.js")}
    K6SCRIPT

    printf '%s' '${var.target_url}' > /opt/loadtest/target-url

    chmod 644 /opt/loadtest/experiment.js
    chmod 644 /opt/loadtest/target-url

    systemctl enable --now amazon-ssm-agent

    # Safety shutdown after 45 minutes.
    shutdown -h +45
  EOF

  user_data_replace_on_change = true

  # If the safety shutdown occurs, terminate rather than merely stop.
  instance_initiated_shutdown_behavior = "terminate"

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm
  ]

  tags = {
    Name      = "group1b-k6-runner"
    Purpose   = "Remote performance testing"
    ManagedBy = "Terraform"
  }
}
