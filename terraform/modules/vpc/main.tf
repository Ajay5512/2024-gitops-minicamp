# modules/vpc/main.tf
# AWS Availability Zones data
data "aws_availability_zones" "available" {}

# Create the VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "${var.app_name}-vpc"
  }
}

# Create the Subnet AZ1
resource "aws_subnet" "subnet-az1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "${var.app_name}-subnet-az1"
  }
}

# Create the Subnet AZ2
resource "aws_subnet" "subnet-az2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "${var.app_name}-subnet-az2"
  }
}

# Create the Subnet AZ3
resource "aws_subnet" "subnet-az3" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_3_cidr
  availability_zone = data.aws_availability_zones.available.names[2]
  tags = {
    Name = "${var.app_name}-subnet-az3"
  }
}

# Create a Security Group
resource "aws_security_group" "security-group" {
  name        = "${var.app_name}-security-group"
  description = "${var.app_name}-security-group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "all traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-security-group"
  }
}

# Create endpoint gateway for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_vpc.vpc.default_route_table_id]
}
