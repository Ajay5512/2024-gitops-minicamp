<<<<<<< HEAD
<<<<<<< HEAD

# modules/vpc/variables.tf
variable "app_name" {
  type        = string
  description = "Application name"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC IPv4 CIDR"
}

variable "subnet_1_cidr" {
  type        = string
  description = "IPv4 CIDR for subnet 1"
}

variable "subnet_2_cidr" {
  type        = string
  description = "IPv4 CIDR for subnet 2"
}

variable "subnet_3_cidr" {
  type        = string
  description = "IPv4 CIDR for subnet 3"
}
=======
=======

>>>>>>> d68a768 (Updated the code)
# modules/vpc/variables.tf
variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of private subnet CIDR blocks"
}

variable "app_name" {
  type        = string
  description = "Application name"
}
<<<<<<< HEAD
>>>>>>> cd2c14e (uPDATE)
=======

variable "environment" {
  type        = string
  description = "Environment (dev/staging/prod)"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}
>>>>>>> d68a768 (Updated the code)
