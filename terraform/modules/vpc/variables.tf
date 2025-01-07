
# modules/vpc/variables.tf
variable "app_name" {
  type        = string
  description = "Application name"
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
