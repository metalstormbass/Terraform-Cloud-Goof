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
  endpoint               = var.email
}

#IAM Role for Lambda Function

resource "aws_iam_role" "mike_vuln_lambda_role" {
    name = "mike_vuln_lambda_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Sid    = ""
            Principal = {
            Service = "lambda.amazonaws.com"
            }
        },
        ]
    })
    managed_policy_arns = [aws_iam_policy.mike_lambda_policy.arn]

}

resource "aws_iam_policy" "mike_lambda_policy" {
  name = "mike_lambda_policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole",
                "s3:*",
                "cloudwatch:*",
                "sns:*"   
            ],
            "Resource": ["*"]
        },    
    ]
  })
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
  function_name = "MikeFunction"

  s3_bucket = aws_s3_bucket.mike_lambda_bucket.id
  s3_key    = aws_s3_object.mike_lambda_bucket_object.key

  runtime = "python3.7"
  handler = "main.lambda_handler"

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

/*
resource "aws_iam_role" "mike_lambda_exec" {
  name = "mike_lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "mike_lambda_policy_attachment" {
  role       = aws_iam_role.mike_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
*/

# API Gateway

resource "aws_api_gateway_rest_api" "mike_lambda_apigw" {
  name        = "mike_api_gw"
}

resource "aws_api_gateway_resource" "mike_aws_apigw_proxy" {
   rest_api_id = aws_api_gateway_rest_api.mike_lambda_apigw.id
   parent_id   = aws_api_gateway_rest_api.mike_lambda_apigw.root_resource_id
   path_part   = "{proxy+}"
}
resource "aws_api_gateway_method" "mike_proxy_method" {
   rest_api_id   = aws_api_gateway_rest_api.mike_lambda_apigw.id
   resource_id   = aws_api_gateway_resource.mike_aws_apigw_proxy.id
   http_method   = "ANY"
   authorization = "NONE"
}
resource "aws_api_gateway_integration" "mike_lambda_integration" {
   rest_api_id = aws_api_gateway_rest_api.mike_lambda_apigw.id
   resource_id = aws_api_gateway_method.mike_proxy_method.resource_id
   http_method = aws_api_gateway_method.mike_proxy_method.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.mike_lambda.invoke_arn
}
resource "aws_api_gateway_method" "mike_proxy_root" {
   rest_api_id   = aws_api_gateway_rest_api.mike_lambda_apigw.id
   resource_id   = aws_api_gateway_rest_api.mike_lambda_apigw.root_resource_id
   http_method   = "ANY"
   authorization = "NONE"
}
resource "aws_api_gateway_integration" "mike_lambda_root" {
   rest_api_id = aws_api_gateway_rest_api.mike_lambda_apigw.id
   resource_id = aws_api_gateway_method.mike_proxy_root.resource_id
   http_method = aws_api_gateway_method.mike_proxy_root.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.mike_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "mike_apideploy" {
   depends_on = [
     aws_api_gateway_integration.mike_lambda_integration,
     aws_api_gateway_integration.mike_lambda_root,
   ]

   rest_api_id = aws_api_gateway_rest_api.mike_lambda_apigw.id
   stage_name  = "snyk_goof_mike_lambda"
}

resource "aws_lambda_permission" "mike_apigw_permission" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.mike_lambda.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.mike_lambda_apigw.execution_arn}/*/*"
}


#Output
output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_api_gateway_deployment.mike_apideploy.invoke_url
}