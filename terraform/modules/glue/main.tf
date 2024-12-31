resource "aws_glue_catalog_database" "enterprise_data_catalog" {
  name         = "enterprise-data-catalog"
  location_uri = "${var.raw_bucket_id}/"
  tags         = var.common_tags
}

resource "aws_glue_crawler" "org_master_crawler" {
  name          = "org-master-data-crawler"
  database_name = aws_glue_catalog_database.enterprise_data_catalog.name
  role          = var.glue_role_arn
  tags          = var.common_tags

  s3_target {
    path = "${var.raw_bucket_id}/master/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
  }

  configuration = <<EOF
{
  "Version":1.0,
  "Grouping": {
    "TableGroupingPolicy": "CombineCompatibleSchemas"
  }
}
EOF
}

resource "aws_glue_trigger" "org_master_crawler_trigger" {
  name = "org-master-crawler-trigger"
  type = "ON_DEMAND"
  tags = var.common_tags

  actions {
    crawler_name = aws_glue_crawler.org_master_crawler.name
  }
}
