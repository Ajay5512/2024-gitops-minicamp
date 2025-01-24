import sys
from unittest.mock import MagicMock, patch

import pytest
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.functions import col
from pyspark.sql.types import StringType, StructField, StructType

# Mock the awsglue module
sys.modules["awsglue"] = MagicMock()
sys.modules["awsglue.context"] = MagicMock()
sys.modules["awsglue.utils"] = MagicMock()
sys.modules["awsglue.transforms"] = MagicMock()

# Mock the getResolvedOptions function
from awsglue.utils import getResolvedOptions

getResolvedOptions = MagicMock(return_value={"JOB_NAME": "test-job"})

# Import the module to test after mocking
from products import clean_products_data, load_products_data, main


@pytest.fixture(scope="session")
def spark_session():
    """Fixture to create a Spark session for testing."""
    spark = (
        SparkSession.builder.appName("pytest-pyspark").master("local[*]").getOrCreate()
    )
    yield spark
    spark.stop()


def test_load_products_data(spark_session):
    """Test loading products data from a CSV file."""
    file_path = "s3a://nexabrands-prod-source/data/products.csv"

    # Mock the Spark read chain
    mock_df = spark_session.createDataFrame(
        [("123 units", "Product A", "Category 1")],
        schema=["PRODUCT_ID", "product.name", "category"],
    )
    with patch(
        "products.spark.read.format.return_value.option.return_value.schema.return_value.load",
        return_value=mock_df,
    ):
        df = load_products_data(file_path)
        assert isinstance(df, DataFrame)
        assert df.columns == ["PRODUCT_ID", "product.name", "category"]


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


@patch("boto3.client")
@patch("pyspark.context.SparkContext")
@patch("awsglue.context.GlueContext")
def test_main_with_mocked_s3(
    mock_glue_context, mock_spark_context, mock_boto_client, spark_session
):
    """Test the main function with mocked GlueContext and S3."""
    # Mock GlueContext and SparkContext
    mock_glue_context.return_value.spark_session = spark_session
    mock_spark_context.return_value = MagicMock()

    # Mock S3 client
    mock_s3 = mock_boto_client.return_value
    mock_s3.list_objects_v2.return_value = {
        "CommonPrefixes": [{"Prefix": "products/temp/category=1/"}]
    }
    mock_s3.copy_object.return_value = {}
    mock_s3.delete_object.return_value = {}

    # Mock the Spark read chain
    mock_df = spark_session.createDataFrame(
        [("123 units", "Product A", "Category 1")],
        schema=["PRODUCT_ID", "product.name", "category"],
    )
    with patch(
        "products.spark.read.format.return_value.option.return_value.schema.return_value.load",
        return_value=mock_df,
    ):
        # Call the main function
        main()

    # Verify S3 and Spark interactions
    mock_spark_context.assert_called_once()
    mock_glue_context.assert_called_once()
    mock_s3.list_objects_v2.assert_called_once()
    mock_s3.copy_object.assert_called_once()
    mock_s3.delete_object.assert_called_once()
