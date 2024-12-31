terraform {
  required_version = ">= 1.9.5" # This will allow 1.10.3 and higher versions
  # # or
  # required_version = "~> 1.10.0"  # This will allow any 1.10.x version

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }

  backend "s3" {
    bucket         = "topdevs-tf-backend"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "topdevsTerraformLocks"
  }
}