import boto3
from botocore.exceptions import ClientError

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table("VisitorCounter")  # Replace with your table name

def lambda_handler(event, context):
    # Define partition key (no sort key needed)
    partition_key = "VisitorId"
    partition_value = "count"  # Assuming you are using a fixed VisitorId for counting

    try:
        # Update the visitor_count field by incrementing it
        response = table.update_item(
            Key={partition_key: partition_value},
            UpdateExpression="SET visitor_count = if_not_exists(visitor_count, :start) + :inc",
            ExpressionAttributeValues={
                ':start': 0,
                ':inc': 1
            },
            ReturnValues="UPDATED_NEW"
        )

        # Get the updated visitor count
        visitor_count = response['Attributes']['visitor_count']
        
        # Create a plain text response
        body = f'{{"visitor_count": {visitor_count}}}'  # Create a valid JSON-like string manually
        
        return {
            'statusCode': 200,
            'body': body,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }

    except ClientError as e:
        # Handle error and return a simple string response for the error
        error_message = f'Error: {e.response["Error"]["Message"]}'
        return {
            'statusCode': 500,
            'body': error_message,
            'headers': {
                'Content-Type': 'text/plain',
                'Access-Control-Allow-Origin': '*'
            }
        }

    
    
