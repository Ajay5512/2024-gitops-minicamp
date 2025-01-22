import logging

from pyspark.sql import SparkSession
from pyspark.sql.functions import (coalesce, col, concat, count, initcap,
                                   isnan, lit, lower, md5, regexp_extract,
                                   regexp_replace, trim, upper, when)
from pyspark.sql.types import DateType, StringType, StructField, StructType


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
    logging.basicConfig(
        level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
    )
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
    return (
        spark.read.format("csv").option("header", True).schema(schema).load(file_path)
    )


# Customers Processing
def clean_customer_names(df):
    return df.na.fill({"customer_name": "Unknown"}).cache()


def remove_trailing_numbers_from_names(df):
    return df.withColumn(
        "customer_name",
        initcap(regexp_replace(col("customer_name"), r"[\d_.\-*]+$", "")),
    ).withColumn("city", regexp_replace(col("city"), r"[\d_.\-*]+$", ""))


def standardize_city_names(df, cities_broadcast):
    return df.withColumn(
        "city",
        when(
            (upper(col("city")).rlike("INVALID_CITY[0-9]*")) | (col("city").isNull()),
            lit("Unknown"),
        ).otherwise(
            when(
                lower(regexp_replace(col("city"), r"[-_]\d+$|[\s]+\d+$", "")).isin(
                    cities_broadcast.value
                ),
                initcap(regexp_replace(col("city"), r"[-_]\d+$|[\s]+\d+$", "")),
            ).otherwise(col("city"))
        ),
    )


def generate_customer_id(df):
    return df.withColumn(
        "customer_id",
        md5(
            concat(
                coalesce(col("customer_name"), lit("")),
                lit("_"),
                coalesce(col("city"), lit("")),
            )
        ),
    ).cache()


def remove_duplicates(df):
    return df.dropDuplicates(["customer_id", "customer_name", "city"])


# Dates Processing
def read_date_data(spark, file_path):
    date_schema = StructType(
        [
            StructField("date", DateType(), True),
            StructField("mmm_yy", StringType(), True),
            StructField("week_no", StringType(), True),
        ]
    )
    return load_data(spark, file_path, date_schema)


def clean_date_data(df):
    cleaned_df = df.na.drop(how="any").filter(
        ~lower(col("mmm_yy")).contains("invalid_date")
    )
    cleaned_df = cleaned_df.withColumn(
        "week_no", regexp_extract(col("week_no"), r"(\d+)", 1)
    )
    return cleaned_df


# Products Processing
def read_products_data(spark, file_path):
    products_schema = StructType(
        [
            StructField("product_id", StringType(), True),
            StructField("product_name", StringType(), True),
            StructField("category", StringType(), True),
        ]
    )
    return load_data(spark, file_path, products_schema)


def clean_product_names(df):
    fill_dict = {"product_name": "Unknown", "category": "Unknown"}
    return df.na.fill(fill_dict)


def clean_and_standardize_products(df):
    cleaned_df = df.select(
        col("product_id"),
        initcap(
            regexp_replace(
                regexp_replace(
                    regexp_replace(col("product_name"), r"[_\-]|\d+$", ""), r"\s+", " "
                ),
                r"\s+$",
                "",
            )
        ).alias("product_name"),
        when(
            (col("category").isNull()) | (col("category") == "InvalidCategory"),
            lit("Unknown"),
        )
        .otherwise(col("category"))
        .alias("category"),
    )
    return cleaned_df.dropDuplicates(["product_id", "product_name", "category"])


def hash_product_ids(df):
    return df.withColumn(
        "product_id",
        md5(
            concat(
                coalesce(col("product_name"), lit("")),
                lit("_"),
                coalesce(col("category"), lit("")),
            )
        ),
    ).select("product_id", "product_name", "category")


# Combined Pipeline
def main():
    spark = create_spark_session(app_name="nexabrands")
    logger = setup_logging()

    # Customers
    logger.info("Processing customers data.")
    source_customers = "s3://nexabrands-prod-source/customers.csv"
    target_customers = "s3://nexabrands-prod-target/processed_customers/"
    customers_schema = StructType(
        [
            StructField("customer_id", StringType(), True),
            StructField("customer_name", StringType(), True),
            StructField("city", StringType(), True),
        ]
    )
    customers_df = load_data(spark, source_customers, customers_schema)
    customers_df = clean_customer_names(customers_df)
    customers_df = remove_trailing_numbers_from_names(customers_df)
    cities = [
        "Johannesburg",
        "Cape Town",
        "Durban",
        "Pretoria",
        "Port Elizabeth",
        "East London",
        "Bloemfontein",
        "Nelspruit",
        "Polokwane",
        "Kimberley",
    ]
    cities_broadcast = spark.sparkContext.broadcast([city.lower() for city in cities])
    customers_df = standardize_city_names(customers_df, cities_broadcast)
    customers_df = generate_customer_id(customers_df)
    customers_df = remove_duplicates(customers_df)
    customers_df.write.mode("overwrite").parquet(target_customers)

    # Dates
    logger.info("Processing dates data.")
    source_dates = "s3://nexabrands-prod-source/date.csv"
    target_dates = "s3://nexabrands-prod-target/processed_dates/"
    dates_df = read_date_data(spark, source_dates)
    dates_df = clean_date_data(dates_df)
    dates_df.write.mode("overwrite").parquet(target_dates)

    # Products
    logger.info("Processing products data.")
    source_products = "s3://nexabrands-prod-source/products.csv"
    target_products = "s3://nexabrands-prod-target/processed_products/"
    products_df = read_products_data(spark, source_products)
    products_df = clean_product_names(products_df)
    products_df = clean_and_standardize_products(products_df)
    products_df = hash_product_ids(products_df)
    products_df.write.mode("overwrite").parquet(target_products)


if __name__ == "__main__":
    main()
