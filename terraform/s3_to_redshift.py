# scripts/s3_to_redshift.py

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

def process_data_type(dtype):
    """Convert Spark data types to Redshift compatible types"""
    if "decimal" in dtype.lower():
        return "DECIMAL(18,2)"
    elif "string" in dtype.lower():
        return "VARCHAR(256)"
    elif "int" in dtype.lower():
        return "INTEGER"
    elif "long" in dtype.lower():
        return "BIGINT"
    elif "double" in dtype.lower():
        return "DOUBLE PRECISION"
    elif "float" in dtype.lower():
        return "REAL"
    elif "bool" in dtype.lower():
        return "BOOLEAN"
    elif "timestamp" in dtype.lower():
        return "TIMESTAMP"
    elif "date" in dtype.lower():
        return "DATE"
    else:
        return "VARCHAR(256)"

def create_table_statement(table_name, schema, schema_name="public"):
    """Generate Redshift CREATE TABLE statement"""
    columns = []
    for col in schema:
        col_name = col.name
        col_type = process_data_type(col.dataType)
        columns.append(f"{col_name} {col_type}")
    
    columns_str = ",\n    ".join(columns)
    return f"""
    CREATE TABLE IF NOT EXISTS {schema_name}.{table_name} (
        {columns_str}
    );
    """

def main():
    # Get job arguments
    args = getResolvedOptions(sys.argv, [
        'JOB_NAME',
        'source-bucket',
        'redshift-database',
        'redshift-schema',
        'redshift-workgroup',
        'redshift-temp-dir'
    ])

    # Initialize Glue context
    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    # Read data from S3
    source_path = f"s3://{args['source-bucket']}/"
    dynamic_frame = glueContext.create_dynamic_frame.from_options(
        connection_type="s3",
        connection_options={"paths": [source_path]},
        format="csv",
        format_options={
            "withHeader": True,
            "separator": ","
        }
    )

    # Convert to DataFrame for some preprocessing if needed
    df = dynamic_frame.toDF()
    
    # Convert back to DynamicFrame
    dynamic_frame_write = DynamicFrame.fromDF(df, glueContext, "dynamic_frame_write")

    # Generate table name from source path
    table_name = args['source-bucket'].split('-')[-1]  # You might want to adjust this logic

    # Create Redshift table if it doesn't exist
    table_schema = dynamic_frame_write.schema()
    create_statement = create_table_statement(table_name, table_schema, args['redshift-schema'])

    # Write to Redshift
    glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame_write,
        connection_type="redshift",
        connection_options={
            "database": args['redshift-database'],
            "dbtable": f"{args['redshift-schema']}.{table_name}",
            "tempdir": args['redshift-temp-dir'],
            "workgroup": args['redshift-workgroup'],
            "preactions": create_statement
        }
    )

    job.commit()

if __name__ == "__main__":
    main()