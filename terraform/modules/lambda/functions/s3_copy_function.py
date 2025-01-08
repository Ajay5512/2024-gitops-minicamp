import boto3
from datetime import datetime

def lambda_handler(event, context):
    # Initialize S3 client
    s3_client = boto3.client('s3')
    
    # Get the source key from the event
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    source_key = event['Records'][0]['s3']['object']['key']
    
    # Extract environment and bucket type from source bucket name
    # Example: if source_bucket is "topdevs-dev-source", 
    # then environment will be "dev" and target will be "target"
    bucket_parts = source_bucket.split('-')
    environment = bucket_parts[1]
    
    # Construct target bucket name following the same pattern
    destination_bucket = f"topdevs-{environment}-target"
    
    try:
        # Copy the object to the destination bucket
        copy_source = {
            'Bucket': source_bucket,
            'Key': source_key
        }
        
        s3_client.copy_object(
            CopySource=copy_source,
            Bucket=destination_bucket,
            Key=source_key
        )
        
        print(f'Successfully copied {source_key} from {source_bucket} to {destination_bucket}')
        return {
            'statusCode': 200,
            'body': f'Successfully copied {source_key} to {destination_bucket}'
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': f'Error copying file: {str(e)}'
        }