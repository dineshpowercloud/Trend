provider "aws" {
  region = "us-east-1"  # Change if needed
}

# Data source to fetch latest Ubuntu 20.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical's AWS account for Ubuntu AMIs

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "trend-vpc" }
}

# First public subnet (us-east-1a)
resource "aws_subnet" "public_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "public-subnet-1" }
}

# Second public subnet (us-east-1b)
resource "aws_subnet" "public_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "public-subnet-2" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# IAM Role for EC2 (Jenkins)
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_policy" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"  # Use least privilege in production
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-profile"
  role = aws_iam_role.jenkins_role.name
}

# EC2 for Jenkins (Ubuntu-based, OpenJDK 17, Docker, Terraform, AWS CLI)
resource "aws_instance" "jenkins" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_1.id
  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name      = "newawskeys"  # Replace with your existing key pair name
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io openjdk-17-jdk wget unzip awscli
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ubuntu
              wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
              echo "deb https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list
              apt-get update -y
              apt-get install -y jenkins
              systemctl start jenkins
              systemctl enable jenkins
              # Install Terraform
              wget https://releases.hashicorp.com/terraform/1.9.7/terraform_1.9.7_linux_amd64.zip
              unzip terraform_1.9.7_linux_amd64.zip
              mv terraform /usr/local/bin/
              rm terraform_1.9.7_linux_amd64.zip
              # Configure AWS CLI (replace with actual credentials or use IAM role)
              mkdir -p /home/ubuntu/.aws
              echo "[default]" > /home/ubuntu/.aws/credentials
              echo "aws_access_key_id = YOUR_ACCESS_KEY_ID" >> /home/ubuntu/.aws/credentials
              echo "aws_secret_access_key = YOUR_SECRET_ACCESS_KEY" >> /home/ubuntu/.aws/credentials
              echo "[default]" > /home/ubuntu/.aws/config
              echo "region = us-east-1" >> /home/ubuntu/.aws/config
              chown -R ubuntu:ubuntu /home/ubuntu/.aws
              chmod 600 /home/ubuntu/.aws/credentials
              EOF
  tags = { Name = "jenkins-ec2-ubuntu" }
}

resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "jenkins-sg" }
}

# Output Jenkins URL
output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}

# EKS Cluster (two subnets)
resource "aws_eks_cluster" "trend_eks" {
  name     = "trend-eks"
  role_arn = aws_iam_role.eks_role.arn
  vpc_config {
    subnet_ids = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  }
  depends_on = [aws_iam_role_policy_attachment.eks_cni_policy]
}

resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_role.name
}
