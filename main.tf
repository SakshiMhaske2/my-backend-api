provider "aws" {
  region = "us-east-1"  # Change this to your desired region
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_execut_role" {
  name = "lambda_execut_role"
  
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })
}

# IAM Policy for Lambda
resource "aws_iam_policy" "lambda_dynamo_policy" {
  name        = "lambda_dynamo_policy"
  description = "Policy to allow lambda function access to DynamoDB"
  
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        "Effect": "Allow",
        "Resource": "${aws_dynamodb_table.VisitorCounter.arn}"
      }
    ]
  })
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execut_role.name
  policy_arn = aws_iam_policy.lambda_dynamo_policy.arn
}


# Create DynamoDB Table
resource "aws_dynamodb_table" "VisitorCounter" {
  name         = "VisitorCounter"
  billing_mode = "PAY_PER_REQUEST"  # Change to "PROVISIONED" if you want to set read/write capacity
  hash_key     = "VisitorId"

  attribute {
    name = "VisitorId"
    type = "S"  # String type
  }
}


# Lambda function
resource "aws_lambda_function" "visitor_counter_function" {
  function_name = "VisitorCounterFunction"
  handler       = "lambda_function.lambda_handler"  # Your handler
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_execut_role.arn
  filename      = "function.zip"
  source_code_hash = filebase64sha256("function.zip")

 environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.VisitorCounter.name
    }
  }
}

# # API Gateway REST API
# resource "aws_api_gateway_rest_api" "visitor_api" {
#   name        = "visitor-api"
#   description = "API to trigger Lambda and show visitor count"
# }

# # API Gateway Resource
# resource "aws_api_gateway_resource" "visitor_resource" {
#   rest_api_id = aws_api_gateway_rest_api.visitor_api.id
#   parent_id   = aws_api_gateway_rest_api.visitor_api.root_resource_id
#   path_part   = "visitor"
# }

# # API Gateway Method (GET)
# resource "aws_api_gateway_method" "get_visitor_count" {
#   rest_api_id   = aws_api_gateway_rest_api.visitor_api.id
#   resource_id   = aws_api_gateway_resource.visitor_resource.id
#   http_method   = "GET"
#   authorization = "NONE"
# }

# # Lambda Integration with API Gateway
# resource "aws_api_gateway_integration" "lambda_integration" {
#   rest_api_id = aws_api_gateway_rest_api.visitor_api.id
#   resource_id = aws_api_gateway_resource.visitor_resource.id
#   http_method = aws_api_gateway_method.get_visitor_count.http_method
#   integration_http_method = "POST"
#   type        = "AWS_PROXY"
#   uri         = aws_lambda_function.visitor_counter_function.invoke_arn
# }

# # API Gateway Deployment
# resource "aws_api_gateway_deployment" "visitor_api_deployment" {
#   depends_on = [aws_api_gateway_integration.lambda_integration]
#   rest_api_id = aws_api_gateway_rest_api.visitor_api.id
#   stage_name  = "prod"
# }

# # Grant API Gateway permission to invoke Lambda
# resource "aws_lambda_permission" "api_gateway_invoke_lambda" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.visitor_counter_function.arn
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.visitor_api.execution_arn}/*/*"
# }




# API Gateway REST API
# Create API Gateway
resource "aws_api_gateway_rest_api" "my_api" {
  name        = "VisitorAPI"
  description = "API for managing visitor count"
}

# Create API Gateway Resource
resource "aws_api_gateway_resource" "visitor" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "visitor"
}

# GET Method
resource "aws_api_gateway_method" "get_visitor" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.visitor.id
  http_method   = "GET"
  authorization = "NONE"
}

# POST Method
resource "aws_api_gateway_method" "post_visitor" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.visitor.id
  http_method   = "POST"
  authorization = "NONE"
}

# Lambda Integration for GET
resource "aws_api_gateway_integration" "get_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.visitor.id
  http_method             = aws_api_gateway_method.get_visitor.http_method
  integration_http_method = "POST"  # The method in Lambda
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.visitor_counter_function.invoke_arn
}

# Lambda Integration for POST
resource "aws_api_gateway_integration" "post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.visitor.id
  http_method             = aws_api_gateway_method.post_visitor.http_method
  integration_http_method = "POST"  # The method in Lambda
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.visitor_counter_function.invoke_arn
}

# Method Response for GET
resource "aws_api_gateway_method_response" "get_response" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.visitor.id
  http_method = aws_api_gateway_method.get_visitor.http_method
  status_code = "200"
}

# Method Response for POST
resource "aws_api_gateway_method_response" "post_response" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.visitor.id
  http_method = aws_api_gateway_method.post_visitor.http_method
  status_code = "200"
}

# Deployment of the API
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name  = "prod"

  depends_on = [
    aws_api_gateway_integration.get_lambda_integration,
    aws_api_gateway_integration.post_lambda_integration,
  ]
}

# Grant API Gateway permissions to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway_invoke_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter_function.arn
  principal     = "apigateway.amazonaws.com"

  # This is needed for the lambda integration
  source_arn = "${aws_api_gateway_rest_api.my_api.execution_arn}/*/*"
}

# Output the API URL
output "api_url" {
  value = "${aws_api_gateway_deployment.api_deployment.invoke_url}/visitor"
}