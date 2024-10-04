import unittest
import json
from moto import mock_dynamodb2
import boto3
from lambda_function import lambda_handler

class TestLambdaFunction(unittest.TestCase):

    @mock_dynamodb2
    def setUp(self):
        # Set up a mock DynamoDB environment
        self.dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        self.table_name = 'VisitorCounter'
        
        # Create a mock table
        self.dynamodb.create_table(
            TableName=self.table_name,
            KeySchema=[
                {
                    'AttributeName': 'VisitorId',
                    'KeyType': 'HASH'  # Partition key
                }
            ],
            AttributeDefinitions=[
                {
                    'AttributeName': 'VisitorId',
                    'AttributeType': 'S'
                }
            ],
            ProvisionedThroughput={
                'ReadCapacityUnits': 5,
                'WriteCapacityUnits': 5
            }
        )
        
        # Add initial item for counting
        self.table = self.dynamodb.Table(self.table_name)
        self.table.put_item(Item={'VisitorId': 'count', 'visitor_count': 0})

    @mock_dynamodb2
    def test_lambda_handler_success(self):
        # Mock the event for a successful count increment
        event = {
            'httpMethod': 'POST',  # Assuming you're triggering the Lambda via a POST request
        }
        context = None
        
        response = lambda_handler(event, context)

        # Check if the response is as expected
        self.assertEqual(response['statusCode'], 200)
        response_body = json.loads(response['body'])
        self.assertEqual(response_body['visitor_count'], 1)

    @mock_dynamodb2
    def test_lambda_handler_increment(self):
        # Mock the event to increment the visitor count
        event = {
            'httpMethod': 'POST',
        }
        context = None
        
        # Increment the count once
        lambda_handler(event, context)
        
        # Call again to increment count to 2
        response = lambda_handler(event, context)

        # Check if the visitor count is now 2
        self.assertEqual(response['statusCode'], 200)
        response_body = json.loads(response['body'])
        self.assertEqual(response_body['visitor_count'], 2)

    @mock_dynamodb2
    def test_lambda_handler_error(self):
        # Simulate an error by trying to update an invalid item
        event = {
            'httpMethod': 'POST',
        }
        
        # Delete the initial item to cause an error
        self.table.delete_item(Key={'VisitorId': 'count'})
        
        response = lambda_handler(event, None)

        # Check if the error response is as expected
        self.assertEqual(response['statusCode'], 500)
        self.assertIn('Error:', response['body'])

if __name__ == '__main__':
    unittest.main()
