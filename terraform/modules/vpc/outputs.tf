
# modules/vpc/outputs.tf
output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_ids" {
  value = [
    aws_subnet.subnet-az1.id,
    aws_subnet.subnet-az2.id,
    aws_subnet.subnet-az3.id
  ]
}

output "security_group_id" {
  value = aws_security_group.security-group.id
}
