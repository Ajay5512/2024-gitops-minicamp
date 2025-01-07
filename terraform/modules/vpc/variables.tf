output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "vpc_endpoint_s3_id" {
  value = aws_vpc_endpoint.s3.id
}

output "vpc_endpoint_redshift_id" {
  value = aws_vpc_endpoint.redshift.id
}

variable "source_bucket" {
  type        = string
  description = "Name of the source S3 bucket"
}

variable "target_bucket" {
  type        = string
  description = "Name of the target S3 bucket"
}

variable "code_bucket" {
  type        = string
  description = "Name of the code bucket"
}