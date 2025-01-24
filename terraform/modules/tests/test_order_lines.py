# test_order_lines.py
import sys
from unittest.mock import MagicMock, patch

import pytest
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.functions import col
from pyspark.sql.types import (
    FloatType,
    IntegerType,
    StringType,
    StructField,
    StructType,
)

# Mock the awsglue module
sys.modules["awsglue"] = MagicMock()
sys.modules["awsglue.context"] = MagicMock()
sys.modules["awsglue.job"] = MagicMock()

# Import the module to test after mocking
from order_lines import (
    clean_actual_delivery_date,
    clean_agreed_delivery_date,
    clean_order_id_and_product_id,
    clean_order_lines_data,
    clean_order_qty_and_delivery_qty,
    convert_column_names_to_lowercase,
    drop_null_values,
    filter_invalid_quantities,
    filter_unwanted_values,
    load_order_lines_data,
)


@pytest.fixture(scope="session")
def spark_session():
    """Fixture to create a Spark session for testing."""
    spark = (
        SparkSession.builder.appName("pytest-pyspark").master("local[*]").getOrCreate()
    )
    yield spark
    spark.stop()


def test_load_order_lines_data(spark_session):
    """Test loading order lines data."""
    mock_df = spark_session.createDataFrame(
        [("ORD123", "PROD456", 10.0, "2023-01-01", "2023-01-05", "5")],
        schema=[
            "ORDER_ID",
            "PRODUCT_ID",
            "ORDER_QTY",
            "AGREED_DELIVERY_DATE",
            "ACTUAL_DELIVERY_DATE",
            "DELIVERY_QTY",
        ],
    )

    # Mock the GlueContext and its spark_session
    mock_glue_context = MagicMock()
    mock_glue_context.spark_session.read.format.return_value.option.return_value.schema.return_value.load.return_value = (
        mock_df
    )

    with patch("order_lines.GlueContext", return_value=mock_glue_context):
        df = load_order_lines_data(mock_glue_context, "s3a://test-bucket/test.csv")
        assert isinstance(df, DataFrame)
        assert df.columns == [
            "ORDER_ID",
            "PRODUCT_ID",
            "ORDER_QTY",
            "AGREED_DELIVERY_DATE",
            "ACTUAL_DELIVERY_DATE",
            "DELIVERY_QTY",
        ]


def test_clean_order_id_and_product_id(spark_session):
    """Test cleaning ORDER_ID and PRODUCT_ID columns."""
    df = spark_session.createDataFrame(
        [(" ord123 ", "PROD-456")],
        schema=["ORDER_ID", "PRODUCT_ID"],
    )
    cleaned_df = clean_order_id_and_product_id(df)
    assert cleaned_df.filter(col("ORDER_ID") == "ORD123").count() == 1
    assert cleaned_df.filter(col("PRODUCT_ID") == 456).count() == 1


def test_clean_order_qty_and_delivery_qty(spark_session):
    """Test cleaning ORDER_QTY and DELIVERY_QTY columns."""
    df = spark_session.createDataFrame(
        [(10.5, "5 units")],
        schema=["ORDER_QTY", "DELIVERY_QTY"],
    )
    cleaned_df = clean_order_qty_and_delivery_qty(df)
    assert cleaned_df.filter(col("ORDER_QTY") == 10).count() == 1
    assert cleaned_df.filter(col("DELIVERY_QTY") == 5).count() == 1


def test_filter_invalid_quantities(spark_session):
    """Test filtering invalid quantities."""
    df = spark_session.createDataFrame(
        [(10, 5), (0, 5), (10, 0)],
        schema=["ORDER_QTY", "DELIVERY_QTY"],
    )
    filtered_df = filter_invalid_quantities(df)
    assert filtered_df.count() == 1


def test_clean_agreed_delivery_date(spark_session):
    """Test cleaning AGREED_DELIVERY_DATE column."""
    df = spark_session.createDataFrame(
        [("01/01/2023",), ("2023-01-01",), ("invalid",)],
        schema=["AGREED_DELIVERY_DATE"],
    )
    cleaned_df = clean_agreed_delivery_date(df)
    assert cleaned_df.filter(col("AGREED_DELIVERY_DATE").isNotNull()).count() == 3


def test_clean_actual_delivery_date(spark_session):
    """Test cleaning ACTUAL_DELIVERY_DATE column."""
    df = spark_session.createDataFrame(
        [("01/01/2023",), ("2023-01-01",), ("invalid",)],
        schema=["ACTUAL_DELIVERY_DATE"],
    )
    cleaned_df = clean_actual_delivery_date(df)
    assert cleaned_df.filter(col("ACTUAL_DELIVERY_DATE").isNotNull()).count() == 3


def test_filter_unwanted_values(spark_session):
    """Test filtering unwanted values."""
    df = spark_session.createDataFrame(
        [("ORD123", "NULL"), ("ORD456", "VALID")],
        schema=["ORDER_ID", "PRODUCT_ID"],
    )
    filtered_df = filter_unwanted_values(df, ["NULL"])
    assert filtered_df.count() == 1


def test_drop_null_values(spark_session):
    """Test dropping null values."""
    df = spark_session.createDataFrame(
        [("ORD123", None), ("ORD456", "PROD456")],
        schema=["ORDER_ID", "PRODUCT_ID"],
    )
    cleaned_df = drop_null_values(df)
    assert cleaned_df.count() == 1


def test_convert_column_names_to_lowercase(spark_session):
    """Test converting column names to lowercase."""
    df = spark_session.createDataFrame(
        [("ORD123", "PROD456")],
        schema=["ORDER_ID", "PRODUCT_ID"],
    )
    cleaned_df = convert_column_names_to_lowercase(df)
    assert cleaned_df.columns == ["order_id", "product_id"]


def test_clean_order_lines_data(spark_session):
    """Test cleaning and transforming order lines data."""
    df = spark_session.createDataFrame(
        [(" ord123 ", "PROD-456", 10.5, "01/01/2023", "2023-01-05", "5 units")],
        schema=[
            "ORDER_ID",
            "PRODUCT_ID",
            "ORDER_QTY",
            "AGREED_DELIVERY_DATE",
            "ACTUAL_DELIVERY_DATE",
            "DELIVERY_QTY",
        ],
    )
    cleaned_df = clean_order_lines_data(df)
    assert cleaned_df.count() == 1
    assert cleaned_df.columns == [
        "order_id",
        "product_id",
        "order_qty",
        "agreed_delivery_date",
        "actual_delivery_date",
        "delivery_qty",
    ]
