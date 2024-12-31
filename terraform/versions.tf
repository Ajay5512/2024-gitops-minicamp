terraform {
  required_version = "~> 1.9.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.69.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.5"
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
  region = var.region
}