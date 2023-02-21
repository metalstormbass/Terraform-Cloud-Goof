#SNS Topic for Lambda Function
resource "aws_sns_topic" "tfgoof_sns_topic" {
  name                        = "${var.victim_company}_sns_topic"
  display_name                = "${var.victim_company}SNSTopic"

  tags =  {
    env = "${var.victim_company}Demo"
    Owner = var.owner
  }
}

resource "aws_sns_topic_subscription" "tfgoof_sns_topic_subscription" {
  topic_arn              = join("", aws_sns_topic.tfgoof_sns_topic.*.arn)
  protocol               = "email"
  endpoint               = var.email
}

#IAM Role for Lambda Function

resource "aws_iam_role" "tfgoof_vuln_lambda_role" {
    name = "${var.victim_company}_vuln_lambda_role"
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
    managed_policy_arns = [aws_iam_policy.tfgoof_lambda_policy.arn]
  tags = {
  Owner = var.owner
  }

}

resource "aws_iam_policy" "tfgoof_lambda_policy" {
  name = "${var.victim_company}_lambda_policy"
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
                "sns:*",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"   
            ],
            "Resource": ["*"]
        },    
    ]
  })
  tags = {
  Owner = var.owner
  }
}

#Lambda Function S3 Bucket


data "archive_file" "lambda_code" {
  type = "zip"

  source_dir  = "${path.module}/lambda_code"
  output_path = "${path.module}/lambda_code.zip"
}

resource "aws_s3_bucket" "tfgoof_lambda_bucket" {
  bucket = "${var.victim_company}-lambda-bucket"
  force_destroy = true

  tags = {
  Owner = var.owner
  }
}


resource "aws_s3_object" "tfgoof_lambda_bucket_object" {
  bucket = aws_s3_bucket.tfgoof_lambda_bucket.id
  force_destroy = true
  key    = "lambda_code.zip"
  source = data.archive_file.lambda_code.output_path

  etag = filemd5(data.archive_file.lambda_code.output_path)
  tags = {
  Owner = var.owner
  }
}

resource "aws_s3_bucket_acl" "tfgoof_lambda_bucket_acl" {
  bucket = aws_s3_bucket.tfgoof_lambda_bucket.id
  acl    = "private"
}

#Lambda Function
resource "aws_lambda_function" "tfgoof_lambda" {
  function_name = "${var.victim_company}Function"

  s3_bucket = aws_s3_bucket.tfgoof_lambda_bucket.id
  s3_key    = aws_s3_object.tfgoof_lambda_bucket_object.key

  runtime = "python3.7"
  handler = "main.lambda_handler"

  source_code_hash = data.archive_file.lambda_code.output_base64sha256

  role = aws_iam_role.tfgoof_vuln_lambda_role.arn
   environment {
        variables = {
        SNS_ARN = aws_sns_topic.tfgoof_sns_topic.arn
        }
    }

  tags = {
  Owner = var.owner
  }
}

resource "aws_cloudwatch_log_group" "tfgoof_lambda_cw_group" {
  name = "/aws/lambda/${aws_lambda_function.tfgoof_lambda.function_name}"

  retention_in_days = 30

  tags = {
  Owner = var.owner
  }
}

# API Gateway

resource "aws_api_gateway_rest_api" "tfgoof_lambda_apigw" {
  name        = "${var.victim_company}_api_gw"

  tags = {
  Owner = var.owner
  }
}

resource "aws_api_gateway_resource" "tfgoof_aws_apigw_proxy" {
   rest_api_id = aws_api_gateway_rest_api.tfgoof_lambda_apigw.id
   parent_id   = aws_api_gateway_rest_api.tfgoof_lambda_apigw.root_resource_id
   path_part   = "{proxy+}"
 
}
resource "aws_api_gateway_method" "tfgoof_proxy_method" {
   rest_api_id   = aws_api_gateway_rest_api.tfgoof_lambda_apigw.id
   resource_id   = aws_api_gateway_resource.tfgoof_aws_apigw_proxy.id
   http_method   = "ANY"
   authorization = "NONE"

}
resource "aws_api_gateway_integration" "tfgoof_lambda_integration" {
   rest_api_id = aws_api_gateway_rest_api.tfgoof_lambda_apigw.id
   resource_id = aws_api_gateway_method.tfgoof_proxy_method.resource_id
   http_method = aws_api_gateway_method.tfgoof_proxy_method.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.tfgoof_lambda.invoke_arn

}
resource "aws_api_gateway_method" "tfgoof_proxy_root" {
   rest_api_id   = aws_api_gateway_rest_api.tfgoof_lambda_apigw.id
   resource_id   = aws_api_gateway_rest_api.tfgoof_lambda_apigw.root_resource_id
   http_method   = "ANY"
   authorization = "NONE"
}
resource "aws_api_gateway_integration" "tfgoof_lambda_root" {
   rest_api_id = aws_api_gateway_rest_api.tfgoof_lambda_apigw.id
   resource_id = aws_api_gateway_method.tfgoof_proxy_root.resource_id
   http_method = aws_api_gateway_method.tfgoof_proxy_root.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.tfgoof_lambda.invoke_arn

}

resource "aws_api_gateway_deployment" "tfgoof_apideploy" {
   depends_on = [
     aws_api_gateway_integration.tfgoof_lambda_integration,
     aws_api_gateway_integration.tfgoof_lambda_root,
   ]

   rest_api_id = aws_api_gateway_rest_api.tfgoof_lambda_apigw.id
   stage_name  = "snyk_goof_${var.victim_company}_lambda"

}

resource "aws_lambda_permission" "tfgoof_apigw_permission" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.tfgoof_lambda.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.tfgoof_lambda_apigw.execution_arn}/*/*"

}


#Output
output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_api_gateway_deployment.tfgoof_apideploy.invoke_url
}