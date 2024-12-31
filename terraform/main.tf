provider "aws" {
  region                   = var.aws_region
  shared_credentials_files = [var.credentials_file]
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

module "s3" {
  source = "./modules/s3"
  
  environment    = var.environment
  project        = var.project
  aws_region     = var.aws_region
  common_tags    = local.common_tags
}

module "iam" {
  source = "./modules/iam"
  
  environment = var.environment
  project     = var.project
}

module "glue" {
  source = "./modules/glue"
  
  environment        = var.environment
  project           = var.project
  raw_bucket_id     = module.s3.raw_bucket_id
  glue_role_arn     = module.iam.glue_role_arn
  common_tags       = local.common_tags
}
