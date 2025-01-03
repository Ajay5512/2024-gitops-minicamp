package terraform

import rego.v1

# Define allowed naming patterns
valid_bucket_pattern := "^topdevs-[a-z]+-[a-z0-9-]+$"

valid_glue_pattern := "^topdevs-[a-z]+-[a-z0-9-]+$"

# Resource limits
glue_job_limits := {
	"max_workers": 2,
	"max_timeout": 2880,
	"max_retries": 1,
	"allowed_worker_types": ["G.1X"],
}

# S3 bucket naming convention check
deny contains msg if {
	some resource in input.resource_changes
	resource.type == "aws_s3_bucket"
	bucket_name := resource.change.after.bucket
	not regex.match(valid_bucket_pattern, bucket_name)
	msg := sprintf(
		"S3 bucket '%s' name does not follow the required pattern. Must match: '%s'",
		[bucket_name, valid_bucket_pattern],
	)
}

# Glue crawler configuration checks
deny contains msg if {
	some resource in input.resource_changes
	resource.type == "aws_glue_crawler"
	crawler := resource.change.after

	# Check schema change policy
	not crawler.schema_change_policy
	msg := sprintf(
		"Glue crawler '%s' must have a schema_change_policy defined",
		[resource.address],
	)
}

deny contains msg if {
	some resource in input.resource_changes
	resource.type == "aws_glue_crawler"
	crawler := resource.change.after

	# Check naming convention
	not regex.match(valid_glue_pattern, crawler.name)
	msg := sprintf(
		"Glue crawler '%s' name does not follow the required pattern. Must match: '%s'",
		[crawler.name, valid_glue_pattern],
	)
}

# Glue job configuration and resource limit checks
deny contains msg if {
	some resource in input.resource_changes
	resource.type == "aws_glue_job"
	job := resource.change.after

	# Check worker count
	job.number_of_workers > glue_job_limits.max_workers
	msg := sprintf(
		"Glue job '%s' exceeds maximum allowed workers. Maximum is %d, got %d",
		[resource.address, glue_job_limits.max_workers, job.number_of_workers],
	)
}

deny contains msg if {
	some resource in input.resource_changes
	resource.type == "aws_glue_job"
	job := resource.change.after

	# Check timeout
	job.timeout > glue_job_limits.max_timeout
	msg := sprintf(
		"Glue job '%s' exceeds maximum allowed timeout. Maximum is %d minutes, got %d",
		[resource.address, glue_job_limits.max_timeout, job.timeout],
	)
}

deny contains msg if {
	some resource in input.resource_changes
	resource.type == "aws_glue_job"
	job := resource.change.after

	# Check max retries
	job.max_retries > glue_job_limits.max_retries
	msg := sprintf(
		"Glue job '%s' exceeds maximum allowed retries. Maximum is %d, got %d",
		[resource.address, glue_job_limits.max_retries, job.max_retries],
	)
}

deny contains msg if {
	some resource in input.resource_changes
	resource.type == "aws_glue_job"
	job := resource.change.after

	# Check worker type
	not job.worker_type in glue_job_limits.allowed_worker_types
	msg := sprintf(
		"Glue job '%s' uses invalid worker type. Allowed types are %v, got %s",
		[resource.address, glue_job_limits.allowed_worker_types, job.worker_type],
	)
}

# Python version check for Glue jobs.
deny contains msg if {
	some resource in input.resource_changes
	resource.type == "aws_glue_job"
	job := resource.change.after

	# Check Python version
	some command in job.command
	not command.python_version == "3"
	msg := sprintf(
		"Glue job '%s' must use Python version 3",
		[resource.address],
	)
}
