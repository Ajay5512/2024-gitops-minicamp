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


def test_clean_products_data_integration(sample_products_df, expected_schema):
    """Integration test for the entire data cleaning pipeline."""
    result_df = clean_products_data(sample_products_df)

    # Check schema
    for field in expected_schema:
        assert field.name in result_df.columns
    assert result_df.schema["product_id"].dataType == IntegerType()

    # Check row count (should filter out rows with nulls or invalid values)
    assert result_df.count() == 7  # Count of valid rows after cleaning

    # Check specific transformations
    laptop_row = result_df.filter(result_df.product_name == "Laptop").collect()[0]
    assert laptop_row.product_id == 1
    assert laptop_row.category == "Electronics"

    # Check that "units" is removed from IDs
    smartphone_row = result_df.filter(result_df.product_name == "Smartphone").collect()[
        0
    ]
    assert smartphone_row.product_id == 2  # P002 units -> 2

    # Check that special characters are removed
    headphones_row = result_df.filter(
        col("product_name").like("%Headphones%")
    ).collect()[0]
    assert "#" not in headphones_row.product_name

    jeans_row = result_df.filter(col("product_name").like("%Jeans%")).collect()[0]
    assert "@" not in jeans_row.product_name

    blender_row = result_df.filter(col("product_name").like("%Blender%")).collect()[0]
    assert "|" not in blender_row.product_name

    # Check whitespace trimming
    lamp_row = result_df.filter(col("product_name").like("%Desk Lamp%")).collect()[0]
    assert lamp_row.product_name == "Desk Lamp"
    assert lamp_row.category == "Home"


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


def test_clean_products_data_invalid_categories(spark_session):
    """Test handling of invalid categories."""
    data = [
        ("P001", "Laptop", "Electronics"),
        ("P002", "Smartphone", ""),
        ("P003", "Headphones", "NULL"),
        ("P004", "T-Shirt", "Unknown"),
        ("P005", "Jeans", "N/A"),
        ("P006", "Coffee Maker", None),
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

    # Only one row should remain with valid category
    assert result_df.count() == 1
    assert result_df.collect()[0].category == "Electronics"


def test_clean_products_data_invalid_product_names(spark_session):
    """Test handling of invalid product names."""
    data = [
        ("P001", "Laptop", "Electronics"),
        ("P002", "", "Electronics"),
        ("P003", "N/A", "Electronics"),
        ("P004", "NULL", "Electronics"),
        ("P005", "Unknown", "Electronics"),
        ("P006", None, "Electronics"),
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

    # Only one row should remain with valid product name
    assert result_df.count() == 1
    assert result_df.collect()[0].product_name == "Laptop"


def test_clean_products_data_product_id_conversion(spark_session):
    """Test that product_id is correctly converted to integer."""
    data = [
        ("P001", "Laptop", "Electronics"),
        ("P002 units", "Smartphone", "Electronics"),
        ("P003", "Headphones", "Electronics"),
        ("P004abc", "T-Shirt", "Apparel"),  # Non-numeric after cleaning
        (None, "Vacuum", "Appliances"),
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

    # Check ID conversion
    assert all(isinstance(row.product_id, int) for row in result_df.collect())
    assert result_df.filter(result_df.product_id == 1).count() == 1
    assert result_df.filter(result_df.product_id == 2).count() == 1  # P002 units -> 2
    assert result_df.filter(result_df.product_id == 3).count() == 1


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
