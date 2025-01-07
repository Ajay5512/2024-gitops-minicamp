# main.tf
provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"

  app_name      = var.app_name
  environment   = var.environment
  aws_region    = var.aws_region
  vpc_cidr      = var.redshift_serverless_vpc_cidr
  subnet_1_cidr = var.redshift_serverless_subnet_1_cidr
  subnet_2_cidr = var.redshift_serverless_subnet_2_cidr
  subnet_3_cidr = var.redshift_serverless_subnet_3_cidr
  source_bucket = var.source_bucket
  target_bucket = var.target_bucket
  code_bucket   = var.code_bucket
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
  source        = "./modules/iam"
  app_name      = var.app_name
  environment   = var.environment
  source_bucket = var.source_bucket
  target_bucket = var.target_bucket
}

module "sns" {
  source        = "./modules/sns"
  environment   = var.environment
  glue_role_arn = module.iam.glue_role_arn
}

<<<<<<< HEAD
module "redshift" {
  source = "./modules/redshift"

  app_name                                = var.app_name
  environment                             = var.environment
  redshift_serverless_namespace_name      = "${var.app_name}-${var.environment}-namespace"
  redshift_serverless_database_name       = "${var.app_name}_${var.environment}_db"
  redshift_serverless_admin_username      = var.redshift_serverless_admin_username
  redshift_serverless_admin_password      = var.redshift_serverless_admin_password
  redshift_serverless_workgroup_name      = var.redshift_serverless_workgroup_name
  redshift_serverless_base_capacity       = var.redshift_serverless_base_capacity
  redshift_serverless_publicly_accessible = var.redshift_serverless_publicly_accessible
  redshift_role_arn                       = module.iam.redshift_role_arn
  security_group_id                       = module.vpc.security_group_id
  subnet_ids                              = module.vpc.subnet_ids
  source_bucket                           = module.s3.source_bucket_name
  target_bucket                           = module.s3.target_bucket_name
}

module "glue" {
  source = "./modules/glue"

  # Connection configuration
  glue_jdbc_conn_name = var.glue_jdbc_conn_name
  redshift_endpoint   = module.redshift.redshift_endpoint
  redshift_port       = "5439"
  redshift_database   = module.redshift.redshift_database_name
  redshift_username   = var.redshift_serverless_admin_username
  redshift_password   = var.redshift_serverless_admin_password
  availability_zone   = data.aws_availability_zones.available.names[0]
  security_group_id   = module.vpc.security_group_id
  subnet_id           = module.vpc.subnet_ids[0]

  # Glue configuration
=======
# Glue Module
module "glue" {
  source                  = "./modules/glue"
>>>>>>> d68a768 (Updated the code)
  source_bucket           = module.s3.source_bucket_id
  target_bucket           = module.s3.target_bucket_id
  code_bucket             = module.s3.code_bucket_id
  glue_role_arn           = module.iam.glue_role_arn
  environment             = var.environment
<<<<<<< HEAD
  sns_topic_arn           = module.sns.topic_arn
  redshift_schema         = "raw"
  redshift_workgroup_name = module.redshift.redshift_workgroup_id

  # Glue job and crawler configuration
  s3_glue_catalog_database_name       = var.s3_glue_catalog_database_name
  redshift_glue_catalog_database_name = var.redshift_glue_catalog_database_name
  s3_glue_crawler_name                = var.s3_glue_crawler_name
  redshift_glue_crawler_name          = var.redshift_glue_crawler_name
  s3_utils_name                       = var.s3_utils_name
  s3_utils_key                        = var.s3_utils_key
  glue_src_path                       = var.glue_src_path
  s3_to_redshift_glue_job_name        = var.s3_to_redshift_glue_job_name
  timeout                             = var.timeout
  glue_version                        = var.glue_version
  number_of_workers                   = var.number_of_workers
  class                               = var.class
  enable-job-insights                 = var.enable-job-insights
  enable-auto-scaling                 = var.enable-auto-scaling
  enable-glue-datacatalog             = var.enable-glue-datacatalog
  job-language                        = var.job-language
  job-bookmark-option                 = var.job-bookmark-option
  datalake-formats                    = var.datalake-formats
  conf                                = var.conf
  glue_trigger_name                   = var.glue_trigger_name
  glue_trigger_schedule_value         = var.glue_trigger_schedule_value
  glue_trigger_schedule_type          = var.glue_trigger_schedule_type
=======
  sns_topic_arn          = module.sns.topic_arn
  redshift_database      = module.redshift.redshift_database_name
  redshift_schema        = "raw"
  redshift_workgroup_name = module.redshift.redshift_workgroup_id

  depends_on = [module.s3, module.redshift]
>>>>>>> d68a768 (Updated the code)
}

module "lambda" {
  source = "./modules/lambda"

  environment   = var.environment
  source_bucket = var.source_bucket
  target_bucket = var.target_bucket

  depends_on = [module.s3]
}

<<<<<<< HEAD
<<<<<<< HEAD
# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
=======
# main.tf
=======


>>>>>>> d68a768 (Updated the code)
module "iam" {
  source = "./modules/iam"
  
  app_name     = var.app_name
  environment  = var.environment
  source_bucket = var.source_bucket
  target_bucket = var.target_bucket
}

module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr            = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  app_name            = var.app_name
  environment         = var.environment
  aws_region          = var.aws_region
}

module "redshift" {
  source = "./modules/redshift"
  
  redshift_serverless_namespace_name = var.redshift_serverless_namespace_name
  redshift_serverless_database_name  = var.redshift_serverless_database_name
  redshift_serverless_admin_username = var.redshift_serverless_admin_username
  redshift_serverless_admin_password = var.redshift_serverless_admin_password
  redshift_serverless_workgroup_name = var.redshift_serverless_workgroup_name
  redshift_serverless_base_capacity  = var.redshift_serverless_base_capacity
  redshift_serverless_publicly_accessible = var.redshift_serverless_publicly_accessible
  
  redshift_role_arn = module.iam.redshift_role_arn
  security_group_id = module.vpc.security_group_id
<<<<<<< HEAD
  subnet_ids = module.vpc.subnet_ids
>>>>>>> cd2c14e (uPDATE)
=======
  subnet_ids        = module.vpc.subnet_ids
  environment       = var.environment
>>>>>>> d68a768 (Updated the code)
}