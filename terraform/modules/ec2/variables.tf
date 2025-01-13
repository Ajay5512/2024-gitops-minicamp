variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "ami_id" {
  type        = string
  description = "ID of the AMI to use for the EC2 instance"
}

variable "instance_type" {
  type        = string
  description = "Type of EC2 instance"
}


variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet"
}

variable "ec2_instance_profile_name" {
  type        = string
  description = "Name of the IAM instance profile for the EC2 instance"
}