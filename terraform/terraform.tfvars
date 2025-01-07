aws_region                = "us-east-1"
environment               = "prod"
vpc_cidr                 = "10.0.0.0/16"  # Add this line if not defined elsewhere
source_bucket             = "source-data"
target_bucket             = "target-data"
code_bucket               = "code-bucket"
script_path               = "./script.py"
schema_change_script_path = "./schema_change.py"