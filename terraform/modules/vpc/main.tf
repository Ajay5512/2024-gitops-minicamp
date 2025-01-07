<<<<<<< HEAD
# modules/vpc/main.tf
data "aws_availability_zones" "available" {}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "${var.app_name}-vpc"
  }
}

resource "aws_subnet" "subnet-az1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "${var.app_name}-subnet-az1"
  }
}

resource "aws_subnet" "subnet-az2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "${var.app_name}-subnet-az2"
  }
}

resource "aws_subnet" "subnet-az3" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_3_cidr
  availability_zone = data.aws_availability_zones.available.names[2]
  tags = {
    Name = "${var.app_name}-subnet-az3"
  }
}

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-security-group"
  }
}




resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.subnet-az1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.subnet-az2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_az3" {
  subnet_id      = aws_subnet.subnet-az3.id
  route_table_id = aws_route_table.private.id
=======

# modules/vpc/main.tf
data "aws_availability_zones" "available" {}

resource "aws_vpc" "redshift-serverless-vpc" {
  cidr_block           = var.redshift_serverless_vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "nsw-properties-redshift-serverless-vpc"
  }
}

resource "aws_subnet" "redshift-serverless-subnet-az1" {
  vpc_id            = aws_vpc.redshift-serverless-vpc.id
  cidr_block        = var.redshift_serverless_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "nsw-properties-redshift-serverless-subnet-az1"
  }
}

resource "aws_subnet" "redshift-serverless-subnet-az2" {
  vpc_id            = aws_vpc.redshift-serverless-vpc.id
  cidr_block        = var.redshift_serverless_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "nsw-properties-redshift-serverless-subnet-az2"
  }
}

resource "aws_subnet" "redshift-serverless-subnet-az3" {
  vpc_id            = aws_vpc.redshift-serverless-vpc.id
  cidr_block        = var.redshift_serverless_subnet_3_cidr
  availability_zone = data.aws_availability_zones.available.names[2]
  tags = {
    Name = "nsw-properties-redshift-serverless-subnet-az3"
  }
}

resource "aws_security_group" "redshift-serverless-security-group" {
  depends_on = [aws_vpc.redshift-serverless-vpc]
  name        = "${var.app_name}-redshift-serverless-security-group"
  description = "${var.app_name}-redshift-serverless-security-group"
  vpc_id = aws_vpc.redshift-serverless-vpc.id
  ingress {
    description = "all traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.app_name}-redshift-serverless-security-group"
  }
}

resource "aws_vpc_endpoint" "s3_redshift" {
  vpc_id            = aws_vpc.redshift-serverless-vpc.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_vpc.redshift-serverless-vpc.default_route_table_id]
}

output "vpc_id" {
  value = aws_vpc.redshift-serverless-vpc.id
}

output "subnet_ids" {
  value = [
    aws_subnet.redshift-serverless-subnet-az1.id,
    aws_subnet.redshift-serverless-subnet-az2.id,
    aws_subnet.redshift-serverless-subnet-az3.id
  ]
}

output "security_group_id" {
  value = aws_security_group.redshift-serverless-security-group.id
>>>>>>> cd2c14e (uPDATE)
}
