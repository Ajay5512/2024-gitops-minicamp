from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, when, lit, regexp_replace, lower, initcap, md5, concat,
    coalesce, isnan, count, upper, trim, regexp_extract
)
from pyspark.sql.types import StructType, StructField, StringType, DateType
import logging

def create_spark_session(app_name="DataProcessing"):
    """
    Creates and returns a Spark session.

    Args:
        app_name (str): Name of the Spark application.

    Returns:
        SparkSession: Initialized Spark session.
    """
    return SparkSession.builder.appName(app_name).getOrCreate()

def setup_logging():
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    return logging.getLogger("DataPipelineLogger")

def load_data(spark, file_path, schema):
    """
    Loads data from a CSV file.

    Args:
        spark (SparkSession): Active Spark session.
        file_path (str): Path to the CSV file.
        schema (StructType): Schema for the data.

    Returns:
        DataFrame: Loaded DataFrame.
    """
    return spark.read.format("csv").option("header", True).schema(schema).load(file_path)

def clean_customer_names(df):
    """
    Replaces null or missing names with 'Unknown'.

    Args:
        df (DataFrame): Input customer DataFrame.

    Returns:
        DataFrame: Cleaned DataFrame with replaced names.
    """
    return df.na.fill({"customer_name": "Unknown"}).cache()

def remove_trailing_numbers_from_names(df):
    """
    Removes trailing numbers and special characters from the 'customer_name' and 'city' columns 
    and converts 'customer_name' to Title Case.

    Args:
        df (DataFrame): Input DataFrame with 'customer_name' and 'city' columns.

    Returns:
        DataFrame: DataFrame with cleaned columns.
    """
    return df.withColumn(
        "customer_name",
        initcap(regexp_replace(col("customer_name"), r"[\d_.\-*]+$", ""))
    ).withColumn(
        "city",
        regexp_replace(col("city"), r"[\d_.\-*]+$", "")
    )

def standardize_city_names(df, cities_broadcast):
    """
    Standardizes city names based on a reference list.

    Args:
        df (DataFrame): Input DataFrame with a 'city' column.
        cities_broadcast (Broadcast): Broadcast variable with city names.

    Returns:
        DataFrame: Cleaned DataFrame with standardized city names.
    """
    return df.withColumn(
        "city",
        when(
            (upper(col("city")).rlike("INVALID_CITY[0-9]*")) | (col("city").isNull()),
            lit("Unknown")
        ).otherwise(
            when(
                lower(regexp_replace(col("city"), r"[-_]\d+$|[\s]+\d+$", ""))
                .isin(cities_broadcast.value),
                initcap(regexp_replace(col("city"), r"[-_]\d+$|[\s]+\d+$", ""))
            ).otherwise(col("city"))
        )
    )

def generate_customer_id(df):
    """
    Generates unique customer IDs using MD5 hash.

    Args:
        df (DataFrame): DataFrame with 'customer_name' and 'city' columns.

    Returns:
        DataFrame: DataFrame with an additional 'customer_id' column.
    """
    return df.withColumn(
        "customer_id",
        md5(concat(
            coalesce(col("customer_name"), lit("")),
            lit("_"),
            coalesce(col("city"), lit(""))
        ))
    ).cache()

def remove_duplicates(df):
    """
    Removes duplicate rows based on key columns.

    Args:
        df (DataFrame): Input DataFrame.

    Returns:
        DataFrame: DataFrame with duplicates removed.
    """
    return df.dropDuplicates(["customer_id", "customer_name", "city"])

def clean_and_process_customers(spark, file_path, target_path):
    logger = setup_logging()

    logger.info("Defining schema for customers data.")
    customers_schema = StructType([
        StructField("customer_id", StringType(), True),
        StructField("customer_name", StringType(), True),
        StructField("city", StringType(), True),
    ])

    logger.info("Loading customer data from source.")
    customers_df = load_data(spark, file_path, customers_schema)

    logger.info("Cleaning customer names.")
    customers_df = clean_customer_names(customers_df)

    logger.info("Removing trailing numbers and special characters from names and city.")
    customers_df = remove_trailing_numbers_from_names(customers_df)

    logger.info("Broadcasting city list for standardization.")
    cities = [
        "Johannesburg", "Cape Town", "Durban", "Pretoria", "Port Elizabeth",
        "East London", "Bloemfontein", "Nelspruit", "Polokwane", "Kimberley"
    ]
    cities_broadcast = spark.sparkContext.broadcast([city.lower() for city in cities])

    logger.info("Standardizing city names.")
    customers_df = standardize_city_names(customers_df, cities_broadcast)

    logger.info("Generating customer IDs.")
    customers_df = generate_customer_id(customers_df)

    logger.info("Removing duplicates.")
    customers_df = remove_duplicates(customers_df)

    logger.info("Saving processed data to target S3 bucket as Parquet.")
    customers_df.write.mode("overwrite").parquet(target_path)

def main():
    spark = create_spark_session(app_name="nexabrands")

    source_path = "s3://nexabrands-prod-source/customers.csv"
    target_path = "s3://nexabrands-prod-target/processed_customers/"

    clean_and_process_customers(spark, source_path, target_path)

if __name__ == "__main__":
    main()
