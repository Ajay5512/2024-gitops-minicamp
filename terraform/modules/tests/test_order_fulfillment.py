import io
from unittest.mock import (
    MagicMock,
    patch,
)

import boto3
import pandas as pd
import pyspark
import pytest
from moto import mock_aws
from order_fulfillment import (
    clean_order_fulfillment_data,
    clean_order_id,
    drop_null_values,
    filter_invalid_order_ids,
    load_order_fulfillment_data,
    rename_columns,
    transform_metrics,
    write_transformed_data,
)
from pyspark.sql import SparkSession
from pyspark.sql.types import (
    FloatType,
    IntegerType,
    StringType,
    StructField,
    StructType,
)


# Fixtures
@pytest.fixture(scope="session")
def spark():
    """Create a SparkSession that will be used by all tests."""
    return (
        SparkSession.builder.master("local[1]")
        .appName("PySpark Unit Tests")
        .getOrCreate()
    )


@pytest.fixture(scope="session")
def glue_context(spark):
    """Create a mock GlueContext that wraps the SparkSession."""
    mock_glue_context = MagicMock()
    mock_glue_context.spark_session = spark
    return mock_glue_context


@pytest.fixture
def sample_data(spark):
    """Create a sample DataFrame that mimics the actual input data format."""
    data = [
        ("FMR32103503", 1.0, 0.0, 0.0),
        ("FMR34103403", 1.0, -1.0, 0.0),
        ("FMR32103602", "1.0 units", 0.0, 0.0),
        ("FMR33103602", 1.0, 0.0, 0.0),
        ("N/A", 0.8, 0.3, 0.5),
        ("NULL", 0.0, 0.8, 0.0),
    ]
    schema = StructType(
        [
            StructField("ORDER_ID", StringType(), True),
            StructField("on.time", FloatType(), True),
            StructField("in_full", FloatType(), True),
            StructField("OTIF", FloatType(), True),
        ]
    )
    return spark.createDataFrame(data, schema)


@pytest.fixture
def s3_bucket():
    """Set up a mock S3 bucket for testing."""
    with mock_aws():
        s3 = boto3.resource("s3", region_name="us-east-1")
        bucket = s3.create_bucket(Bucket="test-bucket")
        yield "test-bucket"


# Tests for rename_columns
def test_rename_columns(spark):
    """Test that columns are renamed correctly to lowercase and 'on.time' becomes 'on_time'."""
    # Setup
    data = [("FMR32103503", 1.0, 0.0, 0.0)]
    schema = StructType(
        [
            StructField("ORDER_ID", StringType(), True),
            StructField("on.time", FloatType(), True),
            StructField("in_full", FloatType(), True),
            StructField("OTIF", FloatType(), True),
        ]
    )
    df = spark.createDataFrame(data, schema)

    # Execute
    result_df = rename_columns(df)

    # Verify
    expected_columns = ["order_id", "on_time", "in_full", "otif"]
    assert result_df.columns == expected_columns
    assert result_df.count() == 1

    # Ensure the data is preserved
    row = result_df.collect()[0]
    assert row["order_id"] == "FMR32103503"
    assert row["on_time"] == 1.0


def test_clean_order_id_with_text_values(spark):
    """Test that order_id is correctly cleaned when it contains text values."""
    # Setup - using the exact format from the sample data with "1.0 units"
    data = [
        ("FMR32103602", "1.0 units", 0.0, 0.0),  # Text in a numeric column
    ]
    schema = StructType(
        [
            StructField("order_id", StringType(), True),
            StructField("on_time", StringType(), True),  # String type for "1.0 units"
            StructField("in_full", FloatType(), True),
            StructField("otif", FloatType(), True),
        ]
    )
    df = spark.createDataFrame(data, schema)

    # Execute
    result_df = clean_order_id(df)

    # Verify
    assert result_df.collect()[0]["order_id"] == "FMR32103602"


# Tests for filter_invalid_order_ids
def test_filter_invalid_order_ids(spark):
    """Test that rows with invalid order_id values are correctly filtered out."""
    # Setup
    data = [
        ("FMR32103503", 1.0, 0.0, 0.0),
        ("N/A", 0.8, 0.3, 0.5),
        ("NONE", 1.0, 0.5, 0.8),
        ("FMR33103602", 1.0, 0.0, 0.0),
        ("NULL", 0.0, 0.8, 0.0),
        ("NA", 0.5, 0.5, 0.5),
        ("unknown", 0.4, 0.4, 0.4),
        ("null", 0.3, 0.3, 0.3),
    ]
    schema = StructType(
        [
            StructField("order_id", StringType(), True),
            StructField("on_time", FloatType(), True),
            StructField("in_full", FloatType(), True),
            StructField("otif", FloatType(), True),
        ]
    )
    df = spark.createDataFrame(data, schema)

    # Execute
    result_df = filter_invalid_order_ids(df)

    # Verify
    assert result_df.count() == 2  # Only the valid FMR order_ids should remain
    valid_order_ids = ["FMR32103503", "FMR33103602"]
    actual_order_ids = [row["order_id"] for row in result_df.collect()]
    for order_id in actual_order_ids:
        assert order_id in valid_order_ids


# Helper function for verifying metric values
def _verify_metric_value(row, field, expected):
    """Helper to verify a metric value, handling None correctly."""
    if expected is None:
        assert row[field] is None
    else:
        assert row[field] == expected


# Tests for transform_metrics using parametrization
@pytest.mark.parametrize(
    "input_data, expected_output",
    [
        # Test case 1: Standard values
        (
            ("FMR32103503", 1.0, 0.0, 0.0),  # Input: order_id, on_time, in_full, otif
            ("FMR32103503", 1, 0, 0),  # Expected: order_id, on_time, in_full, otif
        ),
        # Test case 2: Negative values
        (
            ("FMR34103403", 1.0, -1.0, 0.0),
            ("FMR34103403", 1, 1, 0),  # -1.0 -> 1 based on transform_metrics rules
        ),
        # Test case 3: Fractional values
        (
            ("FMR33103602", 0.4, 0.6, 0.8),
            ("FMR33103602", 0, 1, 1),  # 0.4 -> 0, 0.6 -> 1, 0.8 -> 1
        ),
        # Test case 4: Out-of-range values
        (
            ("FMR33103603", 1.2, 0.3, 1.5),
            ("FMR33103603", None, 0, None),  # 1.2 -> None, 0.3 -> 0, 1.5 -> None
        ),
    ],
)
def test_transform_metrics(spark, input_data, expected_output):
    """Test that metrics are correctly transformed according to the rules."""
    # Setup - using one row at a time for clearer parametrized tests
    data = [input_data]
    schema = StructType(
        [
            StructField("order_id", StringType(), True),
            StructField("on_time", FloatType(), True),
            StructField("in_full", FloatType(), True),
            StructField("otif", FloatType(), True),
        ]
    )
    df = spark.createDataFrame(data, schema)

    # Execute
    result_df = transform_metrics(df)

    # Verify
    actual_row = result_df.collect()[0]
    expected_id, expected_on_time, expected_in_full, expected_otif = expected_output

    assert actual_row["order_id"] == expected_id
    _verify_metric_value(actual_row, "on_time", expected_on_time)
    _verify_metric_value(actual_row, "in_full", expected_in_full)
    _verify_metric_value(actual_row, "otif", expected_otif)


# Tests for drop_null_values
def test_drop_null_values(spark):
    """Test that rows with null values are correctly dropped."""
    # Setup
    data = [
        ("FMR32103503", 1.0, 0.0, 0.0),
        ("FMR34103403", None, -1.0, 0.0),
        ("FMR32103602", 1.0, None, 0.0),
        ("FMR33103602", 1.0, 0.0, None),
        ("FMR33103603", None, None, None),
    ]
    schema = StructType(
        [
            StructField("order_id", StringType(), True),
            StructField("on_time", FloatType(), True),
            StructField("in_full", FloatType(), True),
            StructField("otif", FloatType(), True),
        ]
    )
    df = spark.createDataFrame(data, schema)

    # Execute
    result_df = drop_null_values(df)

    # Verify
    assert result_df.count() == 1  # Only the first row has no nulls
    row = result_df.collect()[0]
    assert row["order_id"] == "FMR32103503"
    assert row["on_time"] == 1.0
    assert row["in_full"] == 0.0
    assert row["otif"] == 0.0


# Helper functions for test_clean_order_fulfillment_data
def _create_test_dataframe(spark):
    """Helper function to create a test dataframe for clean_order_fulfillment_data test."""
    data = [
        ("FMR32103503", 1.0, 0.0, 0.0),
        ("FMR34103403", 1.0, -1.0, 0.0),
        ("FMR33103602", 1.0, 0.0, 0.0),
        ("N/A", 0.8, 0.3, 0.5),
        ("NULL", 0.0, 0.8, 0.0),
    ]
    schema = StructType(
        [
            StructField("ORDER_ID", StringType(), True),
            StructField("on.time", FloatType(), True),
            StructField("in_full", FloatType(), True),
            StructField("OTIF", FloatType(), True),
        ]
    )
    return spark.createDataFrame(data, schema)


def _verify_order_id_in_results(results, order_id):
    """Helper function to verify an order_id exists in results."""
    return order_id in [row["order_id"] for row in results]


def _verify_metrics_for_order(results, order_id, expected_values):
    """Helper function to verify metrics for a specific order."""
    for row in results:
        if row["order_id"] == order_id:
            expected_on_time, expected_in_full, expected_otif = expected_values
            assert row["on_time"] == expected_on_time
            assert row["in_full"] == expected_in_full
            assert row["otif"] == expected_otif
            return True
    return False


# Tests for clean_order_fulfillment_data
def test_clean_order_fulfillment_data(spark):
    """Test the full data cleaning pipeline with actual data format."""
    # Create test data
    fixed_df = _create_test_dataframe(spark)

    # Execute
    result_df = clean_order_fulfillment_data(fixed_df)

    # Verify row count
    assert result_df.count() == 3  # We expect 3 valid rows

    # Collect results for detailed verification
    results = result_df.collect()

    # Verify expected order_ids exist
    expected_order_ids = ["FMR32103503", "FMR34103403", "FMR33103602"]
    for order_id in expected_order_ids:
        assert _verify_order_id_in_results(results, order_id)

    # Verify the metrics were transformed correctly
    assert _verify_metrics_for_order(results, "FMR32103503", (1, 0, 0))
    assert _verify_metrics_for_order(results, "FMR34103403", (1, 1, 0))
    assert _verify_metrics_for_order(results, "FMR33103602", (1, 0, 0))
