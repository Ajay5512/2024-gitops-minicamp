# main.tf
provider "aws" {
  region = var.aws_region
}

module "s3" {
  source = "./modules/s3"

  environment   = var.environment
  source_bucket = var.source_bucket
  target_bucket = var.target_bucket
  code_bucket   = var.code_bucket

  # Source data files
  source_files = {
    "customers.csv" = "${path.root}/modules/data/customers.csv"
    "products.csv"  = "${path.root}/modules/data/products.csv"
    "date.csv"      = "${path.root}/modules/data/date.csv"
  }

  code_files = {
    "script.py"        = "${path.root}/modules/scripts/script.py"
    "schema_change.py" = "${path.root}/modules/scripts/schema_change.py"
  }
}
module "iam" {
  source        = "./modules/iam"
  environment   = var.environment
  source_bucket = var.source_bucket
  target_bucket = var.target_bucket
  code_bucket   = var.code_bucket
  sns_topic_arn = module.sns.topic_arn
}

module "sns" {
  source      = "./modules/sns"
  environment = var.environment
}

module "glue" {
  source        = "./modules/glue"
  source_bucket = module.s3.source_bucket_id
  target_bucket = module.s3.target_bucket_id
  code_bucket   = module.s3.code_bucket_id
  glue_role_arn = module.iam.glue_role_arn
  environment   = var.environment
  sns_topic_arn = module.sns.topic_arn

  # Add these two required arguments
  redshift_database       = var.redshift_serverless_database_name
  redshift_workgroup_name = var.redshift_serverless_workgroup_name
}


module "vpc" {
  source = "./modules/vpc"

  redshift_serverless_vpc_cidr      = var.redshift_serverless_vpc_cidr
  redshift_serverless_subnet_1_cidr = var.redshift_serverless_subnet_1_cidr
  redshift_serverless_subnet_2_cidr = var.redshift_serverless_subnet_2_cidr
  redshift_serverless_subnet_3_cidr = var.redshift_serverless_subnet_3_cidr
  app_name                          = var.app_name
}

module "redshift" {
  source = "./modules/redshift"

  redshift_serverless_namespace_name      = var.redshift_serverless_namespace_name
  redshift_serverless_database_name       = var.redshift_serverless_database_name
  redshift_serverless_admin_username      = var.redshift_serverless_admin_username
  redshift_serverless_admin_password      = var.redshift_serverless_admin_password
  redshift_serverless_workgroup_name      = var.redshift_serverless_workgroup_name
  redshift_serverless_base_capacity       = var.redshift_serverless_base_capacity
  redshift_serverless_publicly_accessible = var.redshift_serverless_publicly_accessible

  redshift_role_arn = module.iam.redshift_role_arn
  security_group_id = module.vpc.security_group_id
  subnet_ids        = module.vpc.subnet_ids
}