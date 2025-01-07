
<<<<<<< HEAD
# modules/vpc/outputs.tf
=======
# Outputs
>>>>>>> d68a768 (Updated the code)
output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_ids" {
<<<<<<< HEAD
  value = [
    aws_subnet.subnet-az1.id,
    aws_subnet.subnet-az2.id,
    aws_subnet.subnet-az3.id
  ]
}

output "security_group_id" {
  value = aws_security_group.security-group.id
}
=======
  value = aws_subnet.private[*].id
}

output "security_group_id" {
  value = aws_security_group.redshift.id
}
>>>>>>> d68a768 (Updated the code)
