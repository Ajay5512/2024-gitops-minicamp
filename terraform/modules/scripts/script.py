import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# Initialize SparkContext, GlueContext, and SparkSession
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# Get job arguments
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'source_path',
    'destination_path'
])

# Create Glue job
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Read from AWS Glue Data Catalog
# Note: Database name follows the pattern defined in terraform: topdevs-${environment}-org-report
source_frame = glueContext.create_dynamic_frame.from_catalog(
    database="topdevs-dev-org-report",  # This will need to be parameterized based on environment
    table_name="organizations",  # This should match your table name after crawling
    transformation_ctx="source_frame_ctx"
)

# Apply schema transformation
mapped_frame = ApplyMapping.apply(
    frame=source_frame,
    mappings=[
        ("index", "long", "index", "int"),
        ("organization id", "string", "organization_id", "string"),
        ("name", "string", "name", "string"),
        ("website", "string", "website", "string"),
        ("country", "string", "country", "string"),
        ("description", "string", "description", "string"),
        ("founded", "long", "founded", "int"),
        ("industry", "string", "industry", "string"),
        ("number of employees", "long", "number_of_employees", "int"),
    ],
    transformation_ctx="mapped_frame_ctx"
)

# Write to S3
glueContext.write_dynamic_frame.from_options(
    frame=mapped_frame,
    connection_type="s3",
    format="csv",
    connection_options={
        "path": args['destination_path'],
        "partitionKeys": []
    },
    transformation_ctx="output_frame_ctx"
)

job.commit()