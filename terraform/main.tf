# main.tf file
provider "aws" {
  region = var.aws_region
}

module "s3" {
  source                     = "./modules/s3"
  source_bucket              = var.source_bucket
  target_bucket              = var.target_bucket
  code_bucket                = var.code_bucket
  environment                = var.environment
  script_path                = var.script_path
  schema_change_script_path  = var.schema_change_script_path
  s3_to_redshift_script_path = "./s3_to_redshift.py"
  organizations_csv_path     = "${path.root}/modules/data/organizations.csv"
}

module "iam" {
  source      = "./modules/iam"
  environment = var.environment

}

module "sns" {
  source        = "./modules/sns"
  environment   = var.environment
  glue_role_arn = module.iam.glue_role_arn
}

module "glue" {
  source                  = "./modules/glue"
  source_bucket           = module.s3.source_bucket_id # Keep only this one
  target_bucket           = module.s3.target_bucket_id
  code_bucket             = module.s3.code_bucket_id # Keep only this one
  glue_role_arn           = module.iam.glue_role_arn
  environment             = var.environment
  sns_topic_arn           = module.sns.topic_arn
  redshift_database       = module.redshift.redshift_database_name
  redshift_schema         = "raw" # or your preferred schema
  redshift_workgroup_name = module.redshift.redshift_workgroup_id
}
# Add to your existing terraform/main.tf
module "lambda" {
  source = "./modules/lambda"

  environment   = var.environment
  source_bucket = var.source_bucket
  target_bucket = var.target_bucket

  depends_on = [module.s3]
}

module "redshift" {
  source = "./modules/redshift"

  app_name    = "topdevs" # Add this line
  environment = var.environment

  vpc_id     = module.vpc.vpc_id
  vpc_cidr   = module.vpc.vpc_cidr
  subnet_ids = module.vpc.private_subnet_ids

  source_bucket = module.s3.source_bucket_name
  target_bucket = module.s3.target_bucket_name

  redshift_serverless_namespace_name = "topdevs-${var.environment}-namespace"
  redshift_serverless_database_name  = "topdevs_${var.environment}_db"
  redshift_serverless_admin_username = var.redshift_serverless_admin_username # Updated variable name
  redshift_serverless_admin_password = var.redshift_serverless_admin_password # Updated variable name

  glue_role_arn = module.iam.glue_role_arn
}


module "vpc" {
  source = "./modules/vpc"

  aws_region    = var.aws_region
  environment   = var.environment
  vpc_cidr      = var.vpc_cidr
  source_bucket = var.source_bucket
  target_bucket = var.target_bucket
  code_bucket   = var.code_bucket
}

# Add to your root variables.tf
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}