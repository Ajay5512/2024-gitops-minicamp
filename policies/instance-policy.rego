package terraform
import rego.v1

# Define allowed naming patterns for S3 buckets
valid_bucket_pattern := "^[a-z0-9]+-[a-z0-9]+-[a-z]+$"

# Define required tags
required_tags := {"Environment", "Project", "Managed_by"}

# Check S3 bucket naming convention and tags
deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_s3_bucket"
    bucket_name := resource.change.after.bucket
    not regex.match(valid_bucket_pattern, bucket_name)
    msg := sprintf(
        "S3 bucket '%s' name does not follow the required pattern. Must match: '%s'",
        [bucket_name, valid_bucket_pattern]
    )
}

# Check for required tags on all resources
deny contains msg if {
    some resource in input.resource_changes
    required_tags_check(resource.change.after.tags)
    missing := required_tags - object.keys(resource.change.after.tags)
    count(missing) > 0
    msg := sprintf(
        "Resource '%s' is missing required tags: %v",
        [resource.address, missing]
    )
}

# Check Glue crawler configuration
deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_glue_crawler"
    not resource.change.after.schema_change_policy
    msg := sprintf(
        "Glue crawler '%s' must have a schema_change_policy defined",
        [resource.address]
    )
}

# Check IAM role policy
deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_iam_role_policy"
    policy := json.unmarshal(resource.change.after.policy)
    not valid_iam_policy(policy)
    msg := sprintf(
        "IAM role policy '%s' contains overly permissive actions or resources",
        [resource.address]
    )
}

# Helper function to check required tags
required_tags_check(tags) if {
    tags != null
} else = false

# Helper function to validate IAM policy
valid_iam_policy(policy) if {
    some statement in policy.Statement
    statement.Effect == "Allow"
    some action in statement.Action
    not action == "*"
    some resource in statement.Resource
    not resource == "*"
} else = false