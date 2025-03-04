from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.functions import (
    col,
    lit,
    regexp_replace,
    to_date,
    trim,
    upper,
    when,
    datediff,
    round
)
from pyspark.sql.types import (
    FloatType,
    IntegerType,
    StringType,
    StructField,
    StructType,
)


def load_order_lines_data(glue_context: GlueContext, s3_input_path: str) -> DataFrame:
    """Load order lines data from a CSV file in S3 using GlueContext."""
    schema = StructType(
        [
            StructField("ORDER_ID", StringType(), True),
            StructField("PRODUCT_ID", StringType(), True),
            StructField("ORDER_QTY", FloatType(), True),
            StructField("AGREED_DELIVERY_DATE", StringType(), True),
            StructField("ACTUAL_DELIVERY_DATE", StringType(), True),
            StructField("DELIVERY_QTY", StringType(), True),
        ]
    )
    return (
        glue_context.spark_session.read.format("csv")
        .option("header", True)
        .schema(schema)
        .load(s3_input_path)
    )


def clean_order_id_and_product_id(df: DataFrame) -> DataFrame:
    """Clean ORDER_ID and PRODUCT_ID columns."""
    return (
        df.withColumn(
            "ORDER_ID",
            upper(regexp_replace(trim(col("ORDER_ID")), r"[^a-zA-Z0-9]", "")),
        )
        .withColumn("PRODUCT_ID", regexp_replace(col("PRODUCT_ID"), r"[^0-9]", ""))
        .withColumn("PRODUCT_ID", col("PRODUCT_ID").cast(IntegerType()))
    )


def clean_order_qty_and_delivery_qty(df: DataFrame) -> DataFrame:
    """Clean ORDER_QTY and DELIVERY_QTY columns."""
    return (
        df.withColumn("ORDER_QTY", col("ORDER_QTY").cast(IntegerType()))
        .withColumn("DELIVERY_QTY", regexp_replace(col("DELIVERY_QTY"), r"[^0-9]", ""))
        .withColumn("DELIVERY_QTY", col("DELIVERY_QTY").cast(IntegerType()))
    )


def filter_invalid_quantities(df: DataFrame) -> DataFrame:
    """Filter out rows with invalid quantities."""
    return df.filter((col("ORDER_QTY") > 0) & (col("DELIVERY_QTY") > 0))


def clean_agreed_delivery_date(df: DataFrame) -> DataFrame:
    """Clean and parse AGREED_DELIVERY_DATE column."""
    return df.withColumn(
        "AGREED_DELIVERY_DATE",
        regexp_replace(
            col("AGREED_DELIVERY_DATE"), r"[^a-zA-Z0-9/,-]", ""
        ),  # Remove special characters
    ).withColumn(
        "AGREED_DELIVERY_DATE",
        regexp_replace(col("AGREED_DELIVERY_DATE"), r"\d{4}", "2024")  # Replace any year with 2024
    ).withColumn(
        "AGREED_DELIVERY_DATE",
        when(
            to_date(col("AGREED_DELIVERY_DATE"), "MM/dd/yyyy").isNotNull(),
            to_date(col("AGREED_DELIVERY_DATE"), "MM/dd/yyyy"),
        )
        .when(
            to_date(col("AGREED_DELIVERY_DATE"), "yyyy-MM-dd").isNotNull(),
            to_date(col("AGREED_DELIVERY_DATE"), "yyyy-MM-dd"),
        )
        .otherwise(
            to_date(lit("2024-01-01"), "yyyy-MM-dd")
        ),  # Default value for invalid dates
    )


def clean_actual_delivery_date(df: DataFrame) -> DataFrame:
    """Clean and parse ACTUAL_DELIVERY_DATE column."""
    return df.withColumn(
        "ACTUAL_DELIVERY_DATE",
        regexp_replace(
            col("ACTUAL_DELIVERY_DATE"), r"[^a-zA-Z0-9/,-]", ""
        ),  # Remove special characters
    ).withColumn(
        "ACTUAL_DELIVERY_DATE",
        regexp_replace(col("ACTUAL_DELIVERY_DATE"), r"\d{4}", "2024")  # Replace any year with 2024
    ).withColumn(
        "ACTUAL_DELIVERY_DATE",
        when(
            to_date(col("ACTUAL_DELIVERY_DATE"), "MM/dd/yyyy").isNotNull(),
            to_date(col("ACTUAL_DELIVERY_DATE"), "MM/dd/yyyy"),
        )
        .when(
            to_date(col("ACTUAL_DELIVERY_DATE"), "yyyy-MM-dd").isNotNull(),
            to_date(col("ACTUAL_DELIVERY_DATE"), "yyyy-MM-dd"),
        )
        .otherwise(
            to_date(lit("2024-01-01"), "yyyy-MM-dd")
        ),  # Default value for invalid dates
    )


def filter_unwanted_values(df: DataFrame, unwanted_values: list) -> DataFrame:
    """Filter out rows with unwanted values in any column."""
    for column in df.columns:
        df = df.filter(~trim(col(column)).isin(unwanted_values))
    return df


def drop_null_values(df: DataFrame) -> DataFrame:
    """Drop rows with null values in any column."""
    return df.dropna()


def convert_column_names_to_lowercase(df: DataFrame) -> DataFrame:
    """Convert column names to lowercase."""
    return df.select([col(c).alias(c.lower()) for c in df.columns])


def add_derived_columns(df: DataFrame) -> DataFrame:
    """Add derived columns for analysis."""
    return df.withColumn(
        "delivery_delay_days",
        datediff(col("actual_delivery_date"), col("agreed_delivery_date"))
    ).withColumn(
        "delivery_completion_rate",
        round(col("delivery_qty") / col("order_qty") * 100, 2)
    ).withColumn(
        "is_on_time",
        when(col("delivery_delay_days") <= 0, "Yes").otherwise("No")
    ).withColumn(
        "is_complete_delivery",
        when(col("delivery_completion_rate") >= 100, "Yes").otherwise("No")
    )


def clean_order_lines_data(df: DataFrame) -> DataFrame:
    """Clean and transform order lines data."""
    # Define unwanted values
    unwanted_values = ["NULL", "null", "NA", "none", "N/A"]

    # Apply transformations
    df = clean_order_id_and_product_id(df)
    df = clean_order_qty_and_delivery_qty(df)
    df = filter_invalid_quantities(df)
    df = clean_agreed_delivery_date(df)
    df = clean_actual_delivery_date(df)
    df = filter_unwanted_values(df, unwanted_values)
    df = drop_null_values(df)
    df = convert_column_names_to_lowercase(df)
    df = add_derived_columns(df)

    return df


if __name__ == "__main__":
    # Initialize Spark session and Glue context
    spark = SparkSession.builder.appName("OrderLinesDataProcessing").getOrCreate()
    glue_context = GlueContext(spark.sparkContext)
    job = Job(glue_context)
    job.init("order-lines-job")

    # S3 paths
    s3_input_path = "s3a://nexabrands-prod-source/data/order_lines.csv"
    s3_output_path = "s3://nexabrands-prod-target/order_lines/processed_data.csv"

    # Load and clean data
    order_lines_df = load_order_lines_data(glue_context, s3_input_path)
    cleaned_order_lines = clean_order_lines_data(order_lines_df)

    # Save the cleaned data to S3 as a CSV file
    cleaned_order_lines.write.mode("overwrite").format("csv").option("header", "true").save(s3_output_path)

    # Commit the Glue job
    job.commit()