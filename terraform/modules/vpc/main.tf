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

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  
  tags = {
    Name = "${var.app_name}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "redshift" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.redshift-serverless"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-az1.id, aws_subnet.subnet-az2.id, aws_subnet.subnet-az3.id]
  security_group_ids  = [aws_security_group.redshift_endpoint.id]
  private_dns_enabled = true
  
  tags = {
    Name = "${var.app_name}-redshift-endpoint"
  }
}

resource "aws_security_group" "redshift_endpoint" {
  name        = "${var.app_name}-redshift-endpoint-sg"
  description = "Security group for Redshift VPC endpoint"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-redshift-endpoint-sg"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.app_name}-private-rt"
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
}
