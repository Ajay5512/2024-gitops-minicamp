# terraform.tfvars
aws_region               = "us-east-1"
environment             = "prod"
source_bucket           = "source-data"
target_bucket           = "target-data"
code_bucket             = "code-bucket"
script_path             = "./script.py"
schema_change_script_path = "./schema_change.py"