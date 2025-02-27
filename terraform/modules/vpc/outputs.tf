# modules/vpc/outputs.tf

output "public_subnet_az1_id" {
  description = "The ID of the public subnet in AZ1."
  value       = aws_subnet.public_subnet_az1.id
}

output "security_group_id" {
  description = "The ID of the security group for Redshift Serverless."
  value       = aws_security_group.redshift-serverless-security-group.id
}