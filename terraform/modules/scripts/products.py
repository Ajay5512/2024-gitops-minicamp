import sys

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


def main():
    input_path = "s3a://nexabrands-prod-source/data/products.csv"
    output_bucket = "nexabrands-prod-target"
    output_path = f"s3a://{output_bucket}/products/products.csv"

    products_df = load_products_data(input_path)
    cleaned_products = clean_products_data(products_df)

    # Write as single CSV file
    cleaned_products.coalesce(1).write \
        .mode("overwrite") \
        .option("header", "true") \
        .option("quote", '"') \
        .option("escape", '"') \
        .csv(output_path)

    print(
        f"Products ETL job completed successfully. CSV output saved to: {output_path}"
    )


if __name__ == "__main__":
    main()