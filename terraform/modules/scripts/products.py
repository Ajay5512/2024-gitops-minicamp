# products.py
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.functions import col, regexp_replace, trim, upper, when
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

    unwanted_values = ["NA", "none", "NULL", "N/A", "Unknown"]

    for column in products_df.columns:
        products_df = products_df.filter(~trim(col(column)).isin(unwanted_values))

    products_df = products_df.withColumn(
        "product_id",
        when(
            (col("product_id").isin("N/A", "Unknown", "null", "None", None))
            | (col("product_id").rlike("[^0-9]")),
            None,
        ).otherwise(
            regexp_replace(col("product_id"), " units", "").cast(IntegerType())
        ),
    )

    products_df = products_df.withColumn(
        "product_name",
        when(
            (col("product_name").isNull())
            | (col("product_name").isin("Unknown", "null", "None", None))
            | (col("product_name").rlike("[^a-zA-Z0-9\\s]")),
            None,
        ).otherwise(trim(col("product_name"))),
    )

    products_df = products_df.withColumn(
        "category",
        when(
            (col("category").isNull())
            | (col("category").isin("Unknown", "null", "None", None))
            | (col("category").rlike("[^a-zA-Z0-9\\s]")),
            None,
        ).otherwise(trim(col("category"))),
    )

    products_df = products_df.dropna()
    return products_df.dropDuplicates()


if __name__ == "__main__":
    spark = SparkSession.builder.appName("ProductsDataProcessing").getOrCreate()

    # S3 paths
    input_path = "s3a://nexabrands-prod-source/data/products.csv"
    output_path = "s3a://nexabrands-prod-target/products/"

    products_df = load_products_data(spark, input_path)
    cleaned_products = clean_products_data(products_df)
    cleaned_products.write.mode("overwrite").parquet(output_path)

    spark.stop()
