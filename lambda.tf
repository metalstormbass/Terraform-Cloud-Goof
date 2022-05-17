#SNS Topic for Lambda Function
resource "aws_sns_topic" "mike_sns_topic" {
  name                        = "mike_sns_topic"
  display_name                = "MikeSNSTopic"

  tags =  {
    ENV = "MikeDemo"
  }
}

resource "aws_sns_topic_subscription" "mike_sns_topic_subscription" {
  topic_arn              = join("", aws_sns_topic.mike_sns_topic.*.arn)
  protocol               = "email"
  endpoint               = ""
}

#IAM Role for Lambda Function
resource "aws_iam_role" "mike_vuln_lambda_role" {
    name = "mike_vuln_lambda_role"
    assume_role_policy = <<EOF
{
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
}
EOF
}

data "aws_iam_policy_document" "mike_lambda_iam" {
    statement {
        actions = [
            "s3:*",
            "sns:*",
        ]
        resources = [
            aws_sns_topic.mike_sns_topic.*.arn,
        ]
    }
}

#Lambda Function S3 Bucket


data "archive_file" "lambda_code" {
  type = "zip"

  source_dir  = "${path.module}/lambda_code"
  output_path = "${path.module}/lambda_code.zip"
}

resource "aws_s3_bucket" "mike_lambda_bucket" {
  bucket = "mike-lambda-bucket"
  force_destroy = true
}


resource "aws_s3_object" "mike_lambda_bucket_object" {
  bucket = aws_s3_bucket.mike_lambda_bucket.id
  force_destroy = true
  key    = "lambda_code.zip"
  source = data.archive_file.lambda_code.output_path

  etag = filemd5(data.archive_file.lambda_code.output_path)
}

resource "aws_s3_bucket_acl" "mike_lambda_bucket_acl" {
  bucket = aws_s3_bucket.mike_lambda_bucket.id
  acl    = "private"
}

#Lambda Function
resource "aws_lambda_function" "mike_lambda" {
  function_name = "HelloWorld"

  s3_bucket = aws_s3_bucket.mike_lambda_bucket.id
  s3_key    = aws_s3_object.mike_lambda_bucket_object.key

  runtime = "python3.7"
  handler = "main.handler"

  source_code_hash = data.archive_file.lambda_code.output_base64sha256

  role = aws_iam_role.mike_vuln_lambda_role.arn
   environment {
        variables = {
        SNS_ARN = aws_sns_topic.mike_sns_topic.arn
        }
    }
}

resource "aws_cloudwatch_log_group" "mike_lambda_cw_group" {
  name = "/aws/lambda/${aws_lambda_function.mike_lambda.function_name}"

  retention_in_days = 30
}

# API Gateway

resource "aws_apigatewayv2_api" "mike_lambda_apigw" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "mike_lambda_apigw_stage" {
  api_id = aws_apigatewayv2_api.mike_lambda_apigw.id

  name        = "mike_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.mike_api_gw_cw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "mike_lambda_apigw_integration" {
  api_id = aws_apigatewayv2_api.mike_lambda_apigw.id

  integration_uri    = aws_lambda_function.mike_lambda.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "ANY"
}

resource "aws_apigatewayv2_route" "mike_api_gw_route" {
  api_id = aws_apigatewayv2_api.mike_lambda.id

  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.mike_lambda_apigw_integration.id}"
}

resource "aws_cloudwatch_log_group" "mike_api_gw_cw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.mike_lambda_apigw.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "mike_api_gw_permissions" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mike_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.mike_lambda_apigw.execution_arn}/*/*"
}

#Output
output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.mike_lambda_apigw_stage.invoke_url
}