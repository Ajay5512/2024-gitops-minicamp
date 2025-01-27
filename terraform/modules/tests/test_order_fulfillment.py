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
from order_fulfillment import (
    clean_order_fulfillment_data,
    clean_order_id,
    drop_null_values,
    filter_invalid_order_ids,
    load_order_fulfillment_data,
    rename_columns,
    transform_metrics,
)


@pytest.fixture(scope="session")
def spark_session():
    """Fixture to create a Spark session for testing."""
    spark = (
        SparkSession.builder.appName("pytest-pyspark").master("local[*]").getOrCreate()
    )
    yield spark
    spark.stop()


def test_load_order_fulfillment_data(spark_session):
    """Test loading order fulfillment data."""
    mock_df = spark_session.createDataFrame(
        [("ORD123", 1.0, 0.5, 0.8)],
        schema=["ORDER_ID", "ON.TIME", "IN_FULL", "OTIF"],
    )

    # Mock the GlueContext and its spark_session
    mock_glue_context = MagicMock()
    mock_glue_context.spark_session.read.format.return_value.option.return_value.schema.return_value.load.return_value = (
        mock_df
    )

    with patch("order_fulfillment.GlueContext", return_value=mock_glue_context):
        df = load_order_fulfillment_data(
            mock_glue_context, "s3a://test-bucket/test.csv"
        )
        assert isinstance(df, DataFrame)
        assert df.columns == ["ORDER_ID", "ON.TIME", "IN_FULL", "OTIF"]


def test_rename_columns(spark_session):
    """Test renaming columns to lowercase and replacing special characters."""
    df = spark_session.createDataFrame(
        [("ORD123", 1.0, 0.5, 0.8)],
        schema=["ORDER_ID", "ON.TIME", "IN_FULL", "OTIF"],
    )
    renamed_df = rename_columns(df)
    assert renamed_df.columns == ["order_id", "on_time", "in_full", "otif"]


def test_clean_order_id(spark_session):
    """Test cleaning the 'order_id' column."""
    df = spark_session.createDataFrame(
        [(" ord123 ", 1.0, 0.5, 0.8)],
        schema=["ORDER_ID", "ON.TIME", "IN_FULL", "OTIF"],
    )
    cleaned_df = clean_order_id(df)
    assert cleaned_df.filter(col("order_id") == "ORD123").count() == 1


def test_filter_invalid_order_ids(spark_session):
    """Test filtering out rows with invalid 'order_id' values."""
    df = spark_session.createDataFrame(
        [("ORD123", 1.0, 0.5, 0.8), ("N/A", 1.0, 0.5, 0.8), ("NULL", 1.0, 0.5, 0.8)],
        schema=["ORDER_ID", "ON.TIME", "IN_FULL", "OTIF"],
    )
    filtered_df = filter_invalid_order_ids(df)
    assert filtered_df.count() == 1


def test_transform_metrics(spark_session):
    """Test transforming the metrics columns ('on_time', 'in_full', 'otif')."""
    df = spark_session.createDataFrame(
        [(1.0, 0.5, 0.8), (-1.0, 1.0, 0.0), (2.0, 3.0, 4.0)],
        schema=["on_time", "in_full", "otif"],
    )
    transformed_df = transform_metrics(df)
    assert transformed_df.filter(col("on_time") == 1).count() == 2
    assert transformed_df.filter(col("in_full") == 0).count() == 1
    assert transformed_df.filter(col("otif").isNull()).count() == 1


def test_drop_null_values(spark_session):
    """Test dropping rows with null values."""
    df = spark_session.createDataFrame(
        [("ORD123", 1.0, 0.5, 0.8), (None, 1.0, 0.5, 0.8)],
        schema=["order_id", "on_time", "in_full", "otif"],  # Changed column names
    )
    cleaned_df = drop_null_values(df)
    assert cleaned_df.count() == 1


def test_clean_order_fulfillment_data(spark_session):
    """Test cleaning and transforming order fulfillment data."""
    df = spark_session.createDataFrame(
        [(" ORD123 ", 1.0, 1.0, 1.0), ("N/A", 1.0, 0.5, 0.8)],
        schema=["ORDER_ID", "ON.TIME", "IN_FULL", "OTIF"],
    )
    cleaned_df = clean_order_fulfillment_data(df)
    assert cleaned_df.count() == 1
    row = cleaned_df.collect()[0]
    assert row.order_id == "ORD123"
