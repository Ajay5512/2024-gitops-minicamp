# VPC Endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "topdevs-${var.environment}-s3-endpoint"
  }
}

# VPC Endpoint for Redshift
resource "aws_vpc_endpoint" "redshift" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.redshift-serverless"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.redshift_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name = "topdevs-${var.environment}-redshift-endpoint"
  }
}

# Security Group for Redshift VPC Endpoint
resource "aws_security_group" "redshift_endpoint" {
  name        = "topdevs-${var.environment}-redshift-endpoint-sg"
  description = "Security group for Redshift VPC endpoint"
  vpc_id      = aws_vpc.main.id

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
    Name = "topdevs-${var.environment}-redshift-endpoint-sg"
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "topdevs-${var.environment}-private-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}