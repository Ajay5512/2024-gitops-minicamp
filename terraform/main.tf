provider "aws" {
  region = var.aws_region
}

module "s3_buckets" {
  source = "./modules/s3"
}

module "glue_setup" {
  source = "./modules/glue"
}

module "iam_roles" {
  source = "./modules/iam"
}