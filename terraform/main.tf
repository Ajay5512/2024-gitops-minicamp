module "s3" {
  source = "./modules/s3"

  environment = var.environment
  project     = var.project
}

module "iam" {
  source = "./modules/iam"

  environment = var.environment
  project     = var.project
}

module "glue" {
  source = "./modules/glue"

  environment           = var.environment
  project               = var.project
  source_bucket_id      = module.s3.source_bucket_id
  target_bucket_id      = module.s3.target_bucket_id
  glue_service_role_arn = module.iam.glue_service_role_arn
}