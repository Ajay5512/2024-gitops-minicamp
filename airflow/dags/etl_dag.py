from datetime import (
    datetime,
    timedelta,
)
from airflow.operators.dummy_operator import DummyOperator
from airflow.providers.amazon.aws.operators.glue import GlueJobOperator
from airflow import DAG
# Import Great Expectations operator
from great_expectations_provider.operators.great_expectations import GreatExpectationsOperator

# Path to the Great Expectations context directory
GX_CONTEXT_ROOT_DIR = "/opt/airflow/include/great_expectations"

# Default arguments for the DAG
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2025, 1, 1),
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Environment configuration
ENV = "prod"
SOURCE_BUCKET = f"nexabrands-{ENV}-source"
TARGET_BUCKET = f"nexabrands-{ENV}-target"

# Create DAG
dag = DAG(
    'topdevs_etl_pipeline',
    default_args=default_args,
    description='ETL pipeline for TopDevs data processing',
    schedule_interval='0 0 * * *',  # Daily at midnight
    catchup=False,
    max_active_runs=1,
    tags=['etl', 'glue', 'topdevs']
)

# Start operator
start = DummyOperator(task_id='start', dag=dag)

# End operator
end = DummyOperator(task_id='end', dag=dag)

# Define job configurations
job_configs = {
    'products': {
        'dependencies': ['start'],
        'validate': True
    },
    'customers': {
        'dependencies': ['start'],
        'validate': True
    },
    'customer_targets': {
        'dependencies': ['customers'],
        'validate': True
    },
    'dates': {
        'dependencies': ['start'],
        'validate': False
    },
    'orders': {
        'dependencies': ['products', 'customers', 'dates'],
        'validate': True
    },
    'order_lines': {
        'dependencies': ['orders'],
        'validate': True
    },
    'order_fulfillment': {
        'dependencies': ['order_lines'],
        'validate': True
    }
}

# Create Glue job tasks
glue_tasks = {}
validate_tasks = {}

for job_name, config in job_configs.items():
    task_id = f"glue_job_{job_name}"
    glue_job_name = f"topdevs-{ENV}-{job_name}-job"
    
    # Define script arguments
    script_args = {
        "--source-path": f"s3://{SOURCE_BUCKET}/",
        "--destination-path": f"s3://{TARGET_BUCKET}/",
        "--job-name": glue_job_name,
        "--enable-auto-scaling": "true",
        "--enable-continuous-cloudwatch-log": "true",
        "--enable-metrics": "true",
        "--environment": ENV
    }
    
    glue_tasks[job_name] = GlueJobOperator(
        task_id=task_id,
        job_name=glue_job_name,
        script_args=script_args,
        region_name='us-east-1',
        wait_for_completion=True,
        num_of_dpus=2,
        dag=dag
    )
    
    # Add validation task if configured
    if config.get('validate', False):
        validate_task_id = f"validate_{job_name}"
        s3_path = f"s3://{TARGET_BUCKET}/{job_name}/"
        
        validate_tasks[job_name] = GreatExpectationsOperator(
            task_id=validate_task_id,
            data_context_root_dir=GX_CONTEXT_ROOT_DIR,
            expectation_suite_name=f"{job_name}_suite",
            data_asset_name=s3_path,  # S3 path to the processed data
            conn_id="aws_default",
            fail_task_on_validation_failure=True,
            return_json_dict=True,
            dag=dag
        )

# Set up task dependencies
for job_name, config in job_configs.items():
    for dep in config['dependencies']:
        if dep == 'start':
            start >> glue_tasks[job_name]
        else:
            glue_tasks[dep] >> glue_tasks[job_name]
    
    # Add validation after Glue job if applicable
    if config.get('validate', False):
        glue_tasks[job_name] >> validate_tasks[job_name]
        
        # Check if this is a final task
        if not any(job_name in c['dependencies'] for c in job_configs.values()):
            validate_tasks[job_name] >> end
    else:
        # If no validation, connect directly to end if final task
        if not any(job_name in c['dependencies'] for c in job_configs.values()):
            glue_tasks[job_name] >> end