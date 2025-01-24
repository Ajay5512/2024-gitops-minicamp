import sys

# AWS GLUE
import boto3
from awsglue.context import GlueContext
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import DataFrame
from pyspark.sql.functions import col, regexp_replace, trim, when
from pyspark.sql.types import StringType, StructField, StructType

args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session


def load_products_data(file_path: str) -> DataFrame:
    """
    Load products data from a CSV file.

    Args:
        file_path (str): The S3 path to the input CSV file.

    Returns:
        DataFrame: A Spark DataFrame containing the loaded products data.
    """
    schema = StructType(
        [
            StructField("PRODUCT_ID", StringType(), True),
            StructField("product.name", StringType(), True),
            StructField("category", StringType(), True),
        ]
    )
    return (
        spark.read.format("csv").option("header", True).schema(schema).load(file_path)
    )


def clean_products_data(df: DataFrame) -> DataFrame:
    """
    Clean and transform products data.

    Args:
        df (DataFrame): A Spark DataFrame containing raw products data.

    Returns:
        DataFrame: A cleaned and transformed Spark DataFrame.
    """
    products_df = df.selectExpr(
        "PRODUCT_ID as product_id", "`product.name` as product_name", "category"
    )

    products_df = products_df.withColumn(
        "category",
        when(
            (col("category").isNull())
            | (trim(col("category")).isin("", "NULL", "Unknown", "N/A")),
            None,
        ).otherwise(trim(col("category"))),
    ).withColumn(
        "product_name",
        when(
            (col("product_name").isNull())
            | (trim(col("product_name")).isin("N/A", "NULL", "Unknown")),
            None,
        ).otherwise(trim(col("product_name"))),
    )

    products_df = products_df.withColumn(
        "product_id", regexp_replace(col("product_id"), " units", "").cast("int")
    ).dropna(subset=["product_id"])

    for column in ["product_name", "category", "product_id"]:
        products_df = products_df.withColumn(
            column, trim(regexp_replace(col(column), r"[|#@$]", ""))
        )

    return products_df.filter(
        (col("product_id").isNotNull())
        & (col("product_name").isNotNull())
        & (col("category").isNotNull())
    )


def rename_s3_file(bucket: str, old_key: str, new_key: str):
    """
    Rename a file in S3.

    Args:
        bucket (str): The name of the S3 bucket.
        old_key (str): The current key of the file to be renamed.
        new_key (str): The new key for the renamed file.

    Returns:
        None
    """
    s3_client = boto3.client("s3")
    copy_source = {"Bucket": bucket, "Key": old_key}
    s3_client.copy_object(CopySource=copy_source, Bucket=bucket, Key=new_key)
    s3_client.delete_object(Bucket=bucket, Key=old_key)


def main():
    input_path = "s3a://nexabrands-prod-source/data/products.csv"
    output_bucket = "nexabrands-prod-target"
    output_prefix = "products/"
    output_path = f"s3a://{output_bucket}/{output_prefix}"
    temp_output_path = f"s3a://{output_bucket}/{output_prefix}temp/"

    products_df = load_products_data(input_path)
    cleaned_products = clean_products_data(products_df)

    cleaned_products.write.mode("overwrite").partitionBy("category").parquet(
        temp_output_path
    )

    s3_client = boto3.client("s3")
    prefix = output_prefix + "temp/"

    response = s3_client.list_objects_v2(
        Bucket=output_bucket, Prefix=prefix, Delimiter="/"
    )
    for common_prefix in response.get("CommonPrefixes", []):
        partition_path = common_prefix["Prefix"]
        category = partition_path.split("=")[-1].rstrip("/")

        partition_files = s3_client.list_objects_v2(
            Bucket=output_bucket, Prefix=partition_path
        )
        for obj in partition_files.get("Contents", []):
            if obj["Key"].endswith(".parquet"):
                old_key = obj["Key"]
                new_key = f"{output_prefix}{category}/product.parquet"
                rename_s3_file(output_bucket, old_key, new_key)
                break

    s3_client.delete_object(Bucket=output_bucket, Key=prefix)

    print(
        f"Products ETL job completed successfully. Partitioned Parquet output saved to: {output_path}"
    )


if __name__ == "__main__":
    main()
