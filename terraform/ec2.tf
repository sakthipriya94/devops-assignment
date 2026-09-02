# -----------------------------
# Latest Amazon Linux 2023 AMI
# -----------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}


# -----------------------------
# IAM Role for EC2
# -----------------------------

resource "aws_iam_role" "ec2" {
  name = "devops-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}


# -----------------------------
# IAM Instance Profile
# -----------------------------

resource "aws_iam_instance_profile" "ec2" {
  name = "devops-ec2-profile"
  role = aws_iam_role.ec2.name
}
resource "aws_iam_role_policy_attachment" "ec2_ecr_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
# -----------------------------
# EC2 Instance
# -----------------------------

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t4g.micro"
  key_name      = "devops-mac-key"
  subnet_id     = aws_subnet.public_1.id

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2.name

  user_data = <<-EOF
              #!/bin/bash

              dnf update -y

              dnf install -y docker

              systemctl enable docker
              systemctl start docker

  usermod -aG docker ec2-user

  systemctl enable amazon-ssm-agent
  systemctl start amazon-ssm-agent
EOF

  tags = {
    Name = "devops-app-server"
  }
}
