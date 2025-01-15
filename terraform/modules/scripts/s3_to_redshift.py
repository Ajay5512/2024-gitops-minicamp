import sys
import boto3
import pandas as pd
import logging
from concurrent.futures import ThreadPoolExecutor
from typing import List, Dict
import pyarrow.parquet as pq
import io
import psycopg2
from psycopg2 import sql

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Get job parameters - simplified version without getResolvedOptions
args = {
    'source-bucket': 'your-bucket-name',  # Replace with your values
    'redshift-database': 'your-database',
    'redshift-schema': 'your-schema',
    'redshift-workgroup': 'your-workgroup',
    'redshift-host': 'your-redshift-host',  # Add your Redshift connection details
    'redshift-port': '5439',
    'redshift-user': 'your-username',
    'redshift-password': 'your-password'
}

# Initialize AWS clients
s3 = boto3.client('s3')
redshift_serverless = boto3.client('redshift-serverless')

class S3ToRedshiftETL:
    def __init__(self):
        self.source_bucket = args['source-bucket']
        self.database = args['redshift-database']
        self.schema = args['redshift-schema']
        self.workgroup = args['redshift-workgroup']
        self.batch_size = 100000
        
        # Redshift connection settings
        self.redshift_conn_string = f"host={args['redshift-host']} dbname={self.database} user={args['redshift-user']} password={args['redshift-password']} port={args['redshift-port']}"
    
    def list_parquet_files(self, prefix: str) -> List[str]:
        """List all parquet files in the given S3 prefix."""
        try:
            paginator = s3.get_paginator('list_objects_v2')
            files = []
            
            for page in paginator.paginate(Bucket=self.source_bucket, Prefix=prefix):
                if 'Contents' in page:
                    files.extend([
                        obj['Key']
                        for obj in page['Contents']
                        if obj['Key'].endswith('.parquet')
                    ])
            
            return files
        except Exception as e:
            logger.error(f"Error listing files in {prefix}: {str(e)}")
            raise

    def read_parquet_from_s3(self, file_key: str) -> pd.DataFrame:
        """Read a parquet file from S3 into a pandas DataFrame."""
        try:
            response = s3.get_object(Bucket=self.source_bucket, Key=file_key)
            parquet_buffer = io.BytesIO(response['Body'].read())
            return pd.read_parquet(parquet_buffer)
        except Exception as e:
            logger.error(f"Error reading parquet file {file_key}: {str(e)}")
            raise

    def create_table_if_not_exists(self, df: pd.DataFrame, table_name: str):
        """Create table in Redshift if it doesn't exist based on DataFrame schema."""
        type_mapping = {
            'int64': 'BIGINT',
            'float64': 'DOUBLE PRECISION',
            'object': 'VARCHAR(MAX)',
            'bool': 'BOOLEAN',
            'datetime64[ns]': 'TIMESTAMP'
        }

        columns = []
        for col_name, dtype in df.dtypes.items():
            sql_type = type_mapping.get(str(dtype), 'VARCHAR(MAX)')
            columns.append(f'"{col_name}" {sql_type}')

        create_table_sql = f"""
        CREATE TABLE IF NOT EXISTS {self.schema}.{table_name} (
            {', '.join(columns)}
        );
        """

        with psycopg2.connect(self.redshift_conn_string) as conn:
            with conn.cursor() as cur:
                cur.execute(create_table_sql)
            conn.commit()

    def copy_to_redshift(self, df: pd.DataFrame, table_name: str):
        """Copy DataFrame to Redshift using COPY command."""
        # Create temporary CSV in memory
        csv_buffer = io.StringIO()
        df.to_csv(csv_buffer, index=False, header=False)
        csv_buffer.seek(0)
        
        with psycopg2.connect(self.redshift_conn_string) as conn:
            with conn.cursor() as cur:
                # Use COPY command to load data
                copy_sql = f"""
                COPY {self.schema}.{table_name}
                FROM STDIN WITH CSV
                """
                cur.copy_expert(sql=copy_sql, file=csv_buffer)
            conn.commit()

    def process_table(self, source_prefix: str, table_name: str) -> None:
        """Process a single table's data from S3 to Redshift."""
        try:
            logger.info(f"Starting processing for table: {table_name}")
            
            # List all parquet files for this table
            parquet_files = self.list_parquet_files(source_prefix)
            
            if not parquet_files:
                logger.warning(f"No parquet files found in {source_prefix}")
                return
                
            # Create table if it doesn't exist using first file
            first_df = self.read_parquet_from_s3(parquet_files[0])
            self.create_table_if_not_exists(first_df, table_name)
            
            # Process files in batches
            for parquet_file in parquet_files:
                logger.info(f"Processing file: {parquet_file}")
                
                df = self.read_parquet_from_s3(parquet_file)
                
                # Process in chunks to optimize memory usage
                for i in range(0, len(df), self.batch_size):
                    chunk = df[i:i + self.batch_size]
                    self.copy_to_redshift(chunk, table_name)
                    
                logger.info(f"Completed processing file: {parquet_file}")
                
            logger.info(f"Completed processing table: {table_name}")
            
        except Exception as e:
            logger.error(f"Error processing table {table_name}: {str(e)}")
            raise

    def run(self):
        """Main ETL process."""
        try:
            # Define table configurations
