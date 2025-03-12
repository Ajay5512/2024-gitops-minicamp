# test_products_etl.py
from unittest.mock import (
    MagicMock,
    patch,
)

import pandas as pd
import pytest

# Import the functions from your module
from products_etl import (
    clean_nulls_and_empty_values,
    clean_products_data,
    clean_special_characters,
    convert_product_id,
    filter_valid_products,
    load_products_data,
    normalize_column_names,
    write_to_csv,
)
from pyspark.sql import SparkSession
from pyspark.sql.types import (
    IntegerType,
    StringType,
    StructField,
    StructType,
)


@pytest.fixture(scope="session")
def spark_session():
    """Create a Spark session for testing."""
    return (
        SparkSession.builder.master("local[1]").appName("PySpark-Testing").getOrCreate()
    )


@pytest.fixture
def sample_data(spark_session):
    """Create sample data for testing."""
    data = [
        ("001", "Product A", "Category 1"),
        ("002 units", "Product B", "Category 2"),
        ("003", "N/A", "Category 3"),
        ("004", "Product D", "Unknown"),
        ("005", "Product E", None),
        ("006#", "Product F@", "Category |6"),
        (None, "Product G", "Category 7"),
    ]

    schema = StructType(
        [
            StructField("PRODUCT_ID", StringType(), True),
            StructField("product.name", StringType(), True),
            StructField("category", StringType(), True),
        ]
    )

    return spark_session.createDataFrame(data, schema)


def test_normalize_column_names(spark_session, sample_data):
    """Test normalizing column names."""
    result = normalize_column_names(sample_data)

    # Check if column names were normalized correctly
    assert "product_id" in result.columns
    assert "product_name" in result.columns
    assert "category" in result.columns

    # Check if the number of rows is preserved
    assert result.count() == sample_data.count()


def test_clean_nulls_and_empty_values(spark_session, sample_data):
    """Test cleaning null and empty values."""
    normalized_df = normalize_column_names(sample_data)
    result = clean_nulls_and_empty_values(normalized_df)

    # Convert to pandas for easier assertion
    pandas_df = result.toPandas()

    # Check that 'N/A' in product_name was converted to None
    assert pandas_df.loc[2, "product_name"] is None

    # Check that 'Unknown' in category was converted to None
    assert pandas_df.loc[3, "category"] is None

    # Check that None in category remains None
    assert pandas_df.loc[4, "category"] is None


def test_convert_product_id(spark_session, sample_data):
    """Test converting product_id."""
    normalized_df = normalize_column_names(sample_data)
    null_cleaned_df = clean_nulls_and_empty_values(normalized_df)
    result = convert_product_id(null_cleaned_df)

    # Convert to pandas for easier assertion
    pandas_df = result.toPandas()

    # Check that rows with None product_id are dropped
    assert len(pandas_df) < len(null_cleaned_df.toPandas())
    assert all(pd.notna(pandas_df["product_id"]))

    # Check that '002 units' was converted to integer 2
    assert 2 in pandas_df["product_id"].values


def test_clean_special_characters(spark_session, sample_data):
    """Test cleaning special characters."""
    normalized_df = normalize_column_names(sample_data)
    null_cleaned_df = clean_nulls_and_empty_values(normalized_df)
    id_cleaned_df = convert_product_id(null_cleaned_df)
    result = clean_special_characters(id_cleaned_df)

    # Convert to pandas for easier assertion
    pandas_df = result.toPandas()

    # Find row with product_id = 6 (after conversion from '006#')
    row_with_special_chars = pandas_df[pandas_df["product_id"] == 6]

    if not row_with_special_chars.empty:
        # Check that special characters were removed
        assert "#" not in str(row_with_special_chars["product_id"].iloc[0])
        assert "@" not in row_with_special_chars["product_name"].iloc[0]
        assert "|" not in row_with_special_chars["category"].iloc[0]


def test_filter_valid_products(spark_session, sample_data):
    """Test filtering valid products."""
    normalized_df = normalize_column_names(sample_data)
    null_cleaned_df = clean_nulls_and_empty_values(normalized_df)
    id_cleaned_df = convert_product_id(null_cleaned_df)
    special_char_cleaned_df = clean_special_characters(id_cleaned_df)
    result = filter_valid_products(special_char_cleaned_df)

    # Convert to pandas for easier assertion
    pandas_df = result.toPandas()

    # Check that all remaining records have non-null values for required fields
    assert pandas_df["product_id"].notna().all()
    assert pandas_df["product_name"].notna().all()
    assert pandas_df["category"].notna().all()


def test_clean_products_data(spark_session, sample_data):
    """Test the complete cleaning process."""
    result = clean_products_data(sample_data)

    # Check that result has the expected columns
    assert set(result.columns) == {"product_id", "product_name", "category"}

    # Check that all records have valid data
    pandas_df = result.toPandas()
    assert pandas_df["product_id"].notna().all()
    assert pandas_df["product_name"].notna().all()
    assert pandas_df["category"].notna().all()


@patch("products_etl.DataFrame.coalesce")
def test_write_to_csv(mock_coalesce, spark_session):
    """Test writing to CSV."""
    # Create a small DataFrame for testing
    test_df = spark_session.createDataFrame(
        [(1, "Product A", "Category 1")], ["product_id", "product_name", "category"]
    )

    # Setup mock for coalesce method
    mock_write = MagicMock()
    mock_mode = MagicMock()
    mock_option1 = MagicMock()
    mock_option2 = MagicMock()

    mock_coalesce.return_value.write = mock_write
    mock_write.mode.return_value = mock_mode
    mock_mode.option.return_value = mock_option1
    mock_option1.option.return_value = mock_option2

    # Call function
    write_to_csv(test_df, "test/path")

    # Verify the calls
    mock_coalesce.assert_called_once_with(1)
    mock_write.mode.assert_called_once_with("overwrite")
    mock_mode.option.assert_called_once_with("header", "true")
    mock_option1.option.assert_called_once_with("quote", '"')


def test_load_products_data(spark_session):
    """Test loading products data with mocked Spark session."""
    # Mock the read methods
    mock_reader = MagicMock()
    spark_session.read = MagicMock()
    spark_session.read.format = MagicMock(return_value=mock_reader)
    mock_reader.option = MagicMock(return_value=mock_reader)
    mock_reader.schema = MagicMock(return_value=mock_reader)
    mock_reader.load = MagicMock(return_value="DataFrame Result")

    # Call the function
    result = load_products_data(spark_session, "test/path")

    # Assertions
    spark_session.read.format.assert_called_once_with("csv")
    mock_reader.option.assert_called_once_with("header", True)
    mock_reader.load.assert_called_once_with("test/path")
    assert result == "DataFrame Result"
