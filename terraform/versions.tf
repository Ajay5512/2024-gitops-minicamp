terraform {
  required_version = "~> 1.9.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }

  backend "s3" {
    bucket         = "gitops-tf-backend"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "GitopsTerraformLocks"
  }
}

provider "aws" {
  region = var.aws_region
}