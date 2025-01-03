# main.tf
provider "aws" {
  region = var.aws_region
}

module "s3" {
  source                    = "./modules/s3"
  source_bucket             = var.source_bucket
  target_bucket             = var.target_bucket
  code_bucket               = var.code_bucket
  environment               = var.environment
  script_path               = var.script_path
  schema_change_script_path = var.schema_change_script_path
  organizations_csv_path    = "${path.root}/modules/data/organizations.csv"
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
  source        = "./modules/glue"
  source_bucket = module.s3.source_bucket_id
  target_bucket = module.s3.target_bucket_id
  code_bucket   = module.s3.code_bucket_id
  glue_role_arn = module.iam.glue_role_arn
  environment   = var.environment
  sns_topic_arn = module.sns.topic_arn
}