# test_products.py
from unittest.mock import MagicMock, patch

import pytest
from products import clean_products_data
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.functions import col
from pyspark.sql.types import StringType, StructField, StructType


@pytest.fixture(scope="session")
def spark_session():
    """Fixture to create a Spark session for testing."""
    spark = (
        SparkSession.builder.appName("pytest-pyspark").master("local[*]").getOrCreate()
    )
    yield spark
    spark.stop()


def test_clean_products_data(spark_session):
    """Test cleaning and transforming products data."""
    schema = StructType(
        [
            StructField("PRODUCT_ID", StringType(), True),
            StructField("product.name", StringType(), True),
            StructField("category", StringType(), True),
        ]
    )
    data = [
        ("123 units", "Product A", "Category 1"),
        ("456 units", "N/A", "Unknown"),
        ("789 units", "Product C", "NULL"),
    ]
    df = spark_session.createDataFrame(data, schema)

    # Clean data using the function
    cleaned_df = clean_products_data(df)

    # Assertions
    assert cleaned_df.count() == 1  # Only one row should remain after cleaning
    assert cleaned_df.columns == ["product_id", "product_name", "category"]
    assert cleaned_df.filter(col("product_id") == 123).count() == 1
    assert cleaned_df.filter(col("product_name") == "Product A").count() == 1
    assert cleaned_df.filter(col("category") == "Category 1").count() == 1


def test_clean_products_data_with_special_characters(spark_session):
    """Test cleaning products data with special characters."""
    schema = StructType(
        [
            StructField("PRODUCT_ID", StringType(), True),
            StructField("product.name", StringType(), True),
            StructField("category", StringType(), True),
        ]
    )
    data = [
        ("123 units", "Product@A", "Category#1"),
        ("456 units", "Product|B", "Category$2"),
    ]
    df = spark_session.createDataFrame(data, schema)

    # Clean data using the function
    cleaned_df = clean_products_data(df)

    # Assertions
    assert cleaned_df.count() == 2
    assert cleaned_df.filter(col("product_name") == "ProductA").count() == 1
    assert cleaned_df.filter(col("category") == "Category1").count() == 1


def test_clean_products_data_with_null_values(spark_session):
    """Test cleaning products data with null values."""
    schema = StructType(
        [
            StructField("PRODUCT_ID", StringType(), True),
            StructField("product.name", StringType(), True),
            StructField("category", StringType(), True),
        ]
    )
    data = [
        ("123 units", None, "Category 1"),
        ("456 units", "Product B", None),
        (None, "Product C", "Category 2"),
    ]
    df = spark_session.createDataFrame(data, schema)

    # Clean data using the function
    cleaned_df = clean_products_data(df)

    # Assertions
    assert cleaned_df.count() == 0  # All rows should be filtered out due to null values


@patch("awsglue.context.GlueContext")
@patch("pyspark.context.SparkContext")
def test_main_with_mocked_glue(mock_spark_context, mock_glue_context, spark_session):
    """Test the main function with mocked GlueContext."""
    # Mock GlueContext and SparkContext
    mock_glue_context.return_value = MagicMock()
    mock_spark_context.return_value = MagicMock()

    # Call the main function
    from products import main

    main()

    # Verify GlueContext and SparkContext calls
    mock_spark_context.assert_called_once()
    mock_glue_context.assert_called_once()
