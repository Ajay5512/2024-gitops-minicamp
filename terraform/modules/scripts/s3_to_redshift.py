import sys
import boto3
import pandas as pd
import awswrangler as wr
import logging
from awsglue.utils import getResolvedOptions
from concurrent.futures import ThreadPoolExecutor
from typing import List, Dict

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Get job parameters
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'source-bucket',
    'redshift-database',
    'redshift-schema',
    'redshift-workgroup'
])

# Initialize AWS clients
s3 = boto3.client('s3')
redshift_serverless = boto3.client('redshift-serverless')

class S3ToRedshiftETL:
    def __init__(self):
        self.source_bucket = args['source-bucket']
        self.database = args['redshift-database']
        self.schema = args['redshift-schema']
        self.workgroup = args['redshift-workgroup']
        
        # Batch size for processing
        self.batch_size = 100000
        
    def list_parquet_files(self, prefix: str) -> List[str]:
        """List all parquet files in the given S3 prefix."""
        try:
            paginator = s3.get_paginator('list_objects_v2')
            files = []
            
            for page in paginator.paginate(Bucket=self.source_bucket, Prefix=prefix):
                if 'Contents' in page:
                    files.extend([
                        f"s3://{self.source_bucket}/{obj['Key']}"
                        for obj in page['Contents']
                        if obj['Key'].endswith('.parquet')
                    ])
            
            return files
        except Exception as e:
            logger.error(f"Error listing files in {prefix}: {str(e)}")
            raise

    def process_table(self, source_prefix: str, table_name: str) -> None:
        """Process a single table's data from S3 to Redshift."""
        try:
            logger.info(f"Starting processing for table: {table_name}")
            
            # List all parquet files for this table
            parquet_files = self.list_parquet_files(source_prefix)
            
            if not parquet_files:
                logger.warning(f"No parquet files found in {source_prefix}")
                return
                
            # Create table if it doesn't exist
            first_batch = wr.s3.read_parquet(
                path=parquet_files[0],
                dataset=False
            )
            
            # Generate CREATE TABLE SQL
            create_table_sql = wr.postgresql.to_sql(
                df=first_batch.head(0),
                con=f"postgresql://@{self.workgroup}/{self.database}",
                schema=self.schema,
                table=table_name,
                mode='create',
                index=False,
                if_exists='replace'
            )
            
            # Process files in batches
            for parquet_file in parquet_files:
                logger.info(f"Processing file: {parquet_file}")
                
                df = wr.s3.read_parquet(
                    path=parquet_file,
                    dataset=False
                )
                
                # Process in chunks to optimize memory usage
                for i in range(0, len(df), self.batch_size):
                    chunk = df[i:i + self.batch_size]
                    
                    wr.redshift.copy(
                        df=chunk,
                        schema=self.schema,
                        table=table_name,
                        database=self.database,
                        workgroup=self.workgroup,
                        mode='append',
                        use_threads=True,
                        num_workers=4
                    )
                    
                logger.info(f"Completed processing file: {parquet_file}")
                
            logger.info(f"Completed processing table: {table_name}")
            
        except Exception as e:
            logger.error(f"Error processing table {table_name}: {str(e)}")
            raise

    def run(self):
        """Main ETL process."""
        try:
            # Define table configurations
            tables = {
                'customers': 'processed_customers/',
                'dates': 'processed_dates/',
                'products': 'processed_products/'
            }
            
            # Process tables in parallel
            with ThreadPoolExecutor(max_workers=3) as executor:
                futures = []
                for table_name, prefix in tables.items():
                    futures.append(
                        executor.submit(self.process_table, prefix, table_name)
                    )
                
                # Wait for all tasks to complete
                for future in futures:
                    future.result()
                    
            logger.info("ETL process completed successfully")
            
        except Exception as e:
            logger.error(f"ETL process failed: {str(e)}")
            raise

def main():
    etl = S3ToRedshiftETL()
    etl.run()

if __name__ == '__main__':
    main()