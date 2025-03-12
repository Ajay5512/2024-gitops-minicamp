from unittest.mock import (
    MagicMock,
    patch,
)

import pandas as pd
import pytest

# Import the functions to test
from products import (
    clean_products_data,
    load_products_data,
)
from pyspark.sql import (
    DataFrame,
    SparkSession,
)
from pyspark.sql.functions import (
    col,
    lit,
)
from pyspark.sql.types import (
    IntegerType,
    StringType,
    StructField,
    StructType,
)


@pytest.fixture(scope="session")
def spark_session():
    """Create a SparkSession that can be reused across tests."""
    spark = (
        SparkSession.builder.master("local[*]")
        .appName("Products_Unit_Tests")
        .getOrCreate()
    )
    yield spark
    spark.stop()


@pytest.fixture
def mock_glue_context(spark_session):
    """Create a mock GlueContext with a reference to the real SparkSession."""
    mock_glue = MagicMock()
    mock_glue.spark_session = spark_session
    return mock_glue


@pytest.fixture
def sample_products_df(spark_session):
    """Create a sample DataFrame for testing."""
    data = [
        ("P001", "Laptop", "Electronics"),
        ("P002 units", "Smartphone", "Electronics"),
        ("P003", "Headphones#", "Electronics"),
        ("P004", "T-Shirt", "Apparel"),
        ("P005", "Jeans@", "Apparel"),
        ("P006", "Coffee Maker", "Kitchen"),
        ("P007", "Blender|", "Kitchen"),
        ("P008", "N/A", "Appliances"),
        ("P009", "Toaster", "NULL"),
        ("P010", "Unknown", "Kitchen"),
        ("P011", "", ""),
        ("P012", "  Desk Lamp  ", "  Home  "),
        (None, "Vacuum", "Appliances"),
        ("P014", None, "Garden"),
        ("P015", "Shovel", None),
    ]
    schema = StructType(
        [
            StructField("PRODUCT_ID", StringType(), True),
            StructField("product.name", StringType(), True),
            StructField("category", StringType(), True),
        ]
    )
    return spark_session.createDataFrame(data=data, schema=schema)


@pytest.fixture
def expected_schema():
    """Define the expected schema after cleaning."""
    return StructType(
        [
            StructField("product_id", IntegerType(), True),
            StructField("product_name", StringType(), True),
            StructField("category", StringType(), True),
        ]
    )


def test_load_products_data(spark_session):
    """Test that load_products_data correctly loads CSV data with the specified schema."""
    # Create a test CSV file
    test_data = pd.DataFrame(
        {
            "PRODUCT_ID": ["P001", "P002", "P003"],
            "product.name": ["Laptop", "Smartphone", "Headphones"],
            "category": ["Electronics", "Electronics", "Electronics"],
        }
    )
    csv_path = "/tmp/test_products.csv"
    test_data.to_csv(csv_path, index=False)

    # Patch the global spark variable
    with patch("products.spark", spark_session):
        result_df = load_products_data(csv_path)

        # Check schema
        assert len(result_df.schema) == 3
        assert "PRODUCT_ID" in result_df.columns
        assert "product.name" in result_df.columns
        assert "category" in result_df.columns

        # Check data
        assert result_df.count() == 3
        assert result_df.filter(result_df.PRODUCT_ID == "P001").count() == 1


def test_clean_products_data_column_renaming(sample_products_df):
    """Test that columns are properly renamed."""
    result_df = clean_products_data(sample_products_df)

    # Check renamed columns
    assert "product_id" in result_df.columns
    assert "product_name" in result_df.columns
    assert "category" in result_df.columns

    # Check original columns are gone
    assert "PRODUCT_ID" not in result_df.columns
    assert "product.name" not in result_df.columns


def test_clean_products_data_special_characters(spark_session):
    """Test removal of special characters from all columns."""
    data = [
        ("P001#", "Laptop|", "Electronics@"),
        ("P002$", "Smartphone#", "Mobile|"),
        ("P003@", "Headphones$", "Audio@"),
    ]
    schema = StructType(
        [
            StructField("PRODUCT_ID", StringType(), True),
            StructField("product.name", StringType(), True),
            StructField("category", StringType(), True),
        ]
    )
    test_df = spark_session.createDataFrame(data=data, schema=schema)

    result_df = clean_products_data(test_df)

    # Check special character removal
    for row in result_df.collect():
        assert all(special_char not in row.product_name for special_char in "|#@$")
        assert all(special_char not in row.category for special_char in "|#@$")
        assert all(special_char not in str(row.product_id) for special_char in "|#@$")


def test_clean_products_data_whitespace_trimming(spark_session):
    """Test trimming of whitespace in all columns."""
    data = [
        ("  P001  ", "  Laptop  ", "  Electronics  "),
        ("P002", " Smartphone ", " Mobile "),
        (" P003 ", "Headphones", "Audio"),
    ]
    schema = StructType(
        [
            StructField("PRODUCT_ID", StringType(), True),
            StructField("product.name", StringType(), True),
            StructField("category", StringType(), True),
        ]
    )
    test_df = spark_session.createDataFrame(data=data, schema=schema)

    result_df = clean_products_data(test_df)

    # Check whitespace trimming
    assert result_df.filter(result_df.product_name == "Laptop").count() == 1
    assert result_df.filter(result_df.product_name == "Smartphone").count() == 1
    assert result_df.filter(result_df.category == "Electronics").count() == 1
    assert result_df.filter(result_df.category == "Mobile").count() == 1


def test_clean_products_data_null_filtering(spark_session):
    """Test that rows with nulls are properly filtered out."""
    data = [
        ("P001", "Laptop", "Electronics"),  # Valid
        ("P002", None, "Electronics"),  # Invalid
        ("P003", "Headphones", None),  # Invalid
        (None, "T-Shirt", "Apparel"),  # Invalid
    ]
    schema = StructType(
        [
            StructField("PRODUCT_ID", StringType(), True),
            StructField("product.name", StringType(), True),
            StructField("category", StringType(), True),
        ]
    )
    test_df = spark_session.createDataFrame(data=data, schema=schema)

    result_df = clean_products_data(test_df)

    # Check null filtering
    assert result_df.count() == 1
    assert result_df.collect()[0].product_name == "Laptop"
