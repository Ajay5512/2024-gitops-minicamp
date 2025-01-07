# modules/redshift/main.tf
resource "aws_redshiftserverless_namespace" "serverless" {
  namespace_name      = var.redshift_serverless_namespace_name
  db_name            = var.redshift_serverless_database_name
  admin_username     = var.redshift_serverless_admin_username
  admin_user_password = var.redshift_serverless_admin_password
  iam_roles          = [var.redshift_role_arn]
<<<<<<< HEAD
<<<<<<< HEAD
  
=======
>>>>>>> cd2c14e (uPDATE)
=======
  
>>>>>>> d68a768 (Updated the code)
  tags = {
    Name = var.redshift_serverless_namespace_name
    Environment = var.environment
  }
}

resource "aws_redshiftserverless_workgroup" "serverless" {
<<<<<<< HEAD
=======
  depends_on = [aws_redshiftserverless_namespace.serverless]
<<<<<<< HEAD
>>>>>>> cd2c14e (uPDATE)
=======
  
>>>>>>> d68a768 (Updated the code)
  namespace_name = aws_redshiftserverless_namespace.serverless.id
  workgroup_name = var.redshift_serverless_workgroup_name
  base_capacity  = var.redshift_serverless_base_capacity
  
  security_group_ids = [var.security_group_id]
<<<<<<< HEAD
<<<<<<< HEAD
  subnet_ids     = var.subnet_ids
  publicly_accessible = var.redshift_serverless_publicly_accessible
  
  tags = {
    Name = var.redshift_serverless_workgroup_name
  }
}
=======
  subnet_ids = var.subnet_ids
=======
  subnet_ids         = var.subnet_ids
>>>>>>> d68a768 (Updated the code)
  publicly_accessible = var.redshift_serverless_publicly_accessible
  
  tags = {
    Name = var.redshift_serverless_workgroup_name
    Environment = var.environment
  }
}
<<<<<<< HEAD
>>>>>>> cd2c14e (uPDATE)
=======
>>>>>>> d68a768 (Updated the code)
