# orders.py
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.functions import (col, regexp_replace, to_date, trim, upper,
                                   when)
from pyspark.sql.types import IntegerType, StringType, StructField, StructType


def load_orders_data(spark: SparkSession, file_path: str) -> DataFrame:
    """Load orders data from a CSV file."""
    schema = StructType(
        [
            StructField("ORDER_ID", StringType(), True),
            StructField("customer_id", StringType(), True),  # Updated column name
            StructField("order_placement_date", StringType(), True),
        ]
    )
    return (
        spark.read.format("csv").option("header", True).schema(schema).load(file_path)
    )


def clean_orders_data(df: DataFrame) -> DataFrame:
    """Clean and transform orders data."""
    orders_df = df.selectExpr(
        "ORDER_ID as order_id",
        "customer_id",  # Updated column name
        "order_placement_date",
    )

    # Define unwanted values
    unwanted_values = ["NA", "none", "NULL", "N/A"]

    # Filter out rows with unwanted values in any column
    for column in orders_df.columns:
        orders_df = orders_df.filter(~trim(col(column)).isin(unwanted_values))

    # Clean order_id
    orders_df = orders_df.withColumn(
        "order_id",
        when(
            (col("order_id").isin("N/A", "Unknown", "null", "None", None))
            | (col("order_id").rlike("[^a-zA-Z0-9]")),
            None,
        ).otherwise(upper(trim(col("order_id")))),
    )

    # Clean customer_id
    orders_df = orders_df.withColumn(
        "customer_id",
        when(
            (col("customer_id").isNull())
            | (col("customer_id").isin("Unknown", "null", "None", None))
            | (col("customer_id").like("ID_%"))
            | (col("customer_id").rlike("[^0-9.]")),
            None,
        ).otherwise(col("customer_id").cast(IntegerType())),
    )

    # Clean and parse order_placement_date
    orders_df = orders_df.withColumn(
        "order_placement_date",
        to_date(
            when(
                col("order_placement_date").rlike(r"^\d{2}/\d{2}/\d{4}$"),
                col("order_placement_date"),
            ).otherwise(
                regexp_replace(col("order_placement_date"), "(?i)([a-z]+,\\s)|\\s+", "")
            ),
            "MM/dd/yyyy",
        ),
    )

    # Drop rows with null values in any column
    orders_df = orders_df.dropna()

    return orders_df.dropDuplicates()


if __name__ == "__main__":
    # Initialize Spark session
    spark = SparkSession.builder.appName("OrdersDataProcessing").getOrCreate()

    # S3 paths
    input_path = "s3a://nexabrands-prod-source/data/orders.csv"
    output_path = "s3a://nexabrands-prod-target/orders/"

    # Load and clean data
    orders_df = load_orders_data(spark, input_path)
    cleaned_orders = clean_orders_data(orders_df)

    # Write to S3 as Parquet
    cleaned_orders.write.mode("overwrite").parquet(output_path)

    # Stop Spark session
    spark.stop()
