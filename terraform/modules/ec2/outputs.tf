
output "subnet_ids" {
  value = [
    aws_subnet.redshift-serverless-subnet-az1.id,
    aws_subnet.redshift-serverless-subnet-az2.id,
    aws_subnet.redshift-serverless-subnet-az3.id
  ]
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet_az1.id
}

output "security_group_id" {
  value = aws_security_group.redshift-serverless-security-group.id
}

output "instance_public_ip" {
  value = aws_instance.rag_cs_instance.public_ip
}