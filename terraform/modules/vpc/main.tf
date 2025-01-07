<<<<<<< HEAD
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

=======
>>>>>>> d68a768 (Updated the code)
# modules/vpc/main.tf
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.app_name}-${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.app_name}-${var.environment}-private-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_security_group" "redshift" {
  name        = "${var.app_name}-${var.environment}-redshift-sg"
  description = "Security group for Redshift Serverless"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5439
    to_port     = 5439
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
    Name        = "${var.app_name}-${var.environment}-redshift-sg"
    Environment = var.environment
  }
}

# VPC Endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name        = "${var.app_name}-${var.environment}-s3-endpoint"
    Environment = var.environment
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.app_name}-${var.environment}-private-rt"
    Environment = var.environment
  }
}

<<<<<<< HEAD
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
=======
# Route Table Association
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
>>>>>>> d68a768 (Updated the code)
}
