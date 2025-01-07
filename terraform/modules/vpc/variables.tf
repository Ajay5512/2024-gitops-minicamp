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
# modules/vpc/variables.tf
variable "redshift_serverless_vpc_cidr" {
  type        = string
  description = "VPC IPv4 CIDR"
}

variable "redshift_serverless_subnet_1_cidr" {
  type        = string
  description = "IPv4 CIDR for Redshift subnet 1"
}

variable "redshift_serverless_subnet_2_cidr" {
  type        = string
  description = "IPv4 CIDR for Redshift subnet 2"
}

variable "redshift_serverless_subnet_3_cidr" {
  type        = string
  description = "IPv4 CIDR for Redshift subnet 3"
}

variable "app_name" {
  type        = string
  description = "Application name"
}
>>>>>>> cd2c14e (uPDATE)
