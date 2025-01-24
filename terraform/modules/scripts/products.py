# products.py
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.functions import col, regexp_replace, trim, when
from pyspark.sql.types import IntegerType, StringType, StructField, StructType


def load_products_data(spark: SparkSession, file_path: str) -> DataFrame:
    """
    Load products data from a CSV file.

    Args:
        spark (SparkSession): An active Spark session.
        file_path (str): The path to the CSV file containing products data.

    Returns:
        DataFrame: A Spark DataFrame containing the loaded data with a defined schema.
    """
    schema = StructType(
        [
            StructField("PRODUCT_ID", StringType(), True),
            StructField(
                "product.name", StringType(), True
            ),  # Ensure this matches the CSV header
            StructField("category", StringType(), True),
        ]
    )
    return (
        spark.read.format("csv").option("header", True).schema(schema).load(file_path)
    )


def clean_products_data(df: DataFrame) -> DataFrame:
    """
    Clean and transform products data.

    The function performs the following operations:
    - Filters out rows with unwanted values in any column.
    - Cleans and standardizes the `product_id` column.
    - Validates and cleans the `product_name` and `category` columns.
    - Drops rows with null values and removes duplicates.

    Args:
        df (DataFrame): A Spark DataFrame containing the raw products data.

    Returns:
        DataFrame: A cleaned and transformed Spark DataFrame.
    """
    products_df = df.selectExpr(
        "PRODUCT_ID as product_id",
        "`product.name` as product_name",  # Escaped column name
        "category",
    )

    # Define unwanted values
    unwanted_values = ["NA", "none", "NULL", "N/A", "Unknown"]

    # Filter out rows with unwanted values
    for column in products_df.columns:
        products_df = products_df.filter(~trim(col(column)).isin(unwanted_values))

    # Clean and standardize the `product_id` column
    products_df = products_df.withColumn(
        "product_id",
        regexp_replace(col("product_id"), " units", "").cast(IntegerType()),
    )

    # Clean and standardize the `product_name` and `category` columns
    for column in ["product_name", "category"]:
        products_df = products_df.withColumn(
            column,
            when(
                (col(column).isNull()) | (trim(col(column)).isin(unwanted_values)),
                None,
            ).otherwise(trim(col(column))),
        )

    # Remove special characters from `product_name` and `category`
    for column in ["product_name", "category"]:
        products_df = products_df.withColumn(
            column,
            regexp_replace(col(column), r"[|#@$]", ""),
        )

    # Drop rows with null values
    products_df = products_df.dropna()

    # Remove duplicates
    products_df = products_df.dropDuplicates()

    return products_df


if __name__ == "__main__":
    spark = SparkSession.builder.appName("ProductsDataProcessing").getOrCreate()

    # S3 paths
    input_path = "s3a://nexabrands-prod-source/data/products.csv"
    output_path = "s3a://nexabrands-prod-target/products/"

    products_df = load_products_data(spark, input_path)
    cleaned_products = clean_products_data(products_df)
    cleaned_products.write.mode("overwrite").parquet(output_path)

    spark.stop()
