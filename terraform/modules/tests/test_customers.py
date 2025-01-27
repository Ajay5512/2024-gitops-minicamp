import sys
from unittest.mock import MagicMock, patch

import pytest
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.functions import col
from pyspark.sql.types import FloatType, StringType, StructField, StructType

# Mock the awsglue module
sys.modules["awsglue"] = MagicMock()
sys.modules["awsglue.context"] = MagicMock()
sys.modules["awsglue.job"] = MagicMock()

# Import the module to test after mocking
from customers import (
    clean_customer_data,
    clean_customer_id,
    clean_string_columns,
    drop_na_and_duplicates,
    load_customers_data,
    rename_columns_to_lowercase,
    trim_string_columns,
)


@pytest.fixture(scope="session")
def spark_session():
    """Fixture to create a Spark session for testing."""
    spark = (
        SparkSession.builder.appName("pytest-pyspark").master("local[*]").getOrCreate()
    )
    yield spark
    spark.stop()


def test_load_customers_data(spark_session):
    """Test loading customers data."""
    mock_df = spark_session.createDataFrame(
        [(1.0, "John Doe", "New York")],
        schema=["CUSTOMER_ID", "customer_name", "city"],
    )

    # Mock the GlueContext and its spark_session
    mock_glue_context = MagicMock()
    mock_glue_context.spark_session.read.format.return_value.option.return_value.schema.return_value.load.return_value = (
        mock_df
    )

    with patch("customers.GlueContext", return_value=mock_glue_context):
        df = load_customers_data(mock_glue_context, "s3a://test-bucket/test.csv")
        assert isinstance(df, DataFrame)
        assert df.columns == ["CUSTOMER_ID", "customer_name", "city"]


def test_drop_na_and_duplicates(spark_session):
    """Test dropping rows with null values and duplicates."""
    df = spark_session.createDataFrame(
        [
            (1.0, "John Doe", "New York"),
            (None, "Jane Doe", "Chicago"),
            (1.0, "John Doe", "New York"),
        ],
        schema=["CUSTOMER_ID", "customer_name", "city"],
    )
    cleaned_df = drop_na_and_duplicates(df)
    assert cleaned_df.count() == 1


def test_trim_string_columns(spark_session):
    """Test trimming whitespace from string columns."""
    df = spark_session.createDataFrame(
        [(1.0, " John Doe ", " New York ")],
        schema=["CUSTOMER_ID", "customer_name", "city"],
    )
    trimmed_df = trim_string_columns(df)
    assert trimmed_df.filter(col("customer_name") == "John Doe").count() == 1


def test_clean_customer_id(spark_session):
    """Test cleaning the 'CUSTOMER_ID' column."""
    df = spark_session.createDataFrame(
        [(1.0, "John Doe", "New York"), (2.5, "Jane Doe", "Chicago")],
        schema=["CUSTOMER_ID", "customer_name", "city"],
    )
    cleaned_df = clean_customer_id(df)
    assert cleaned_df.filter(col("CUSTOMER_ID") == 1).count() == 1


def test_clean_string_columns(spark_session):
    """Test cleaning and formatting string columns."""
    df = spark_session.createDataFrame(
        [(1.0, "john-doe", "new_york")],
        schema=["CUSTOMER_ID", "customer_name", "city"],
    )
    cleaned_df = clean_string_columns(df, ["customer_name", "city"])
    assert cleaned_df.filter(col("customer_name") == "John Doe").count() == 1


def test_rename_columns_to_lowercase(spark_session):
    """Test renaming columns to lowercase."""
    df = spark_session.createDataFrame(
        [(1.0, "John Doe", "New York")],
        schema=["CUSTOMER_ID", "customer_name", "city"],
    )
    renamed_df = rename_columns_to_lowercase(df)
    assert renamed_df.columns == ["customer_id", "customer_name", "city"]


def test_clean_customer_data(spark_session):
    """Test cleaning and transforming customer data."""
    df = spark_session.createDataFrame(
        [(1.0, " john-doe ", " new_york "), (2.5, "Jane Doe", "Chicago")],
        schema=["CUSTOMER_ID", "customer_name", "city"],
    )
    cleaned_df = clean_customer_data(df)
    assert cleaned_df.count() == 1
    row = cleaned_df.collect()[0]
    assert row.customer_id == 1
    assert row.customer_name == "John Doe"
    assert row.city == "New York"
