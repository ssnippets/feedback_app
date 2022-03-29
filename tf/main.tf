provider "aws" {
    region = "us-east-2"
}

resource "aws_db_instance" "default" {
  allocated_storage      = 20
  engine                 = "postgres"
  db_name                = "database_production"
  username               = "lambdauser"
  skip_final_snapshot    = true
  instance_class         = "db.t3.micro"
  password               = var.db_password
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.sg_rds.id]
}


/////////////////security groups
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}
resource "aws_default_subnet" "default" {
  availability_zone = "us-east-2a"

  tags = {
    Name = "Default subnet for us-east-2a"
  }
}
resource "aws_security_group" "sg_lambda" {
  vpc_id      = aws_default_vpc.default.id
  name        = "LambdaSecurityGroup"
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

 resource "aws_security_group" "sg_rds" {
  name        = "RDSLambdaSecurityGroup"
  # vpc_id      = aws_default_vpc.default.id

  ingress {
    description      = "Postgres from sg_lambda"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # security_groups = [aws_security_group.sg_lambda.id]

    # security_group_id  = aws_security_group.sg_lambda.id
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
//////////////////
// Lambda:
# resource "aws_iam_role" "iam_for_lambda" {
#   name = "iam_for_lambda"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

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
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "feedback_app" {
  filename      = "feedback_app.zip"
  function_name = "feedback_app"
#   role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"

#  vpc_config {
    # Every subnet should be able to reach an EFS mount target in the same Availability Zone. Cross-AZ mounts are not permitted.
    # subnet_ids         = [aws_default_subnet.default.id]
    # security_group_ids = [aws_security_group.sg_lambda.id]
  # }
  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("feedback_app.zip")

  runtime = "nodejs14.x"

  role = aws_iam_role.lambda_exec.arn
  timeout = 10
  environment {
    variables = {
      POSTGRES_DB = aws_db_instance.default.db_name
      POSTGRES_USER = aws_db_instance.default.username
      POSTGRES_PASSWORD = aws_db_instance.default.password
      POSTGRES_HOST = aws_db_instance.default.address
      POSTGRES_PORT = aws_db_instance.default.port
      ENVIRONMENT = "production"
      NODE_ENV = "production"
    }
  }
}


// API GATEWAY
resource "aws_api_gateway_rest_api" "feedback_app" {
  name        = "FeedbackApp"
#   protocol_type = "HTTP"
  description = "Feedback Application"
}

# resource "aws_api_gateway_stage" "lambda" {
#   rest_api_id = aws_api_gateway_rest_api.feedback_app.id
#   deployment_id = aws_api_gateway_deployment.feedback_app.id
#   stage_name = "curr"
# #   name        = "test"
# #   auto_deploy = true

#   access_log_settings {
#     destination_arn = aws_cloudwatch_log_group.feedback_app.arn

#     format = jsonencode({
#       requestId               = "$context.requestId"
#       sourceIp                = "$context.identity.sourceIp"
#       requestTime             = "$context.requestTime"
#       protocol                = "$context.protocol"
#       httpMethod              = "$context.httpMethod"
#       resourcePath            = "$context.resourcePath"
#       routeKey                = "$context.routeKey"
#       status                  = "$context.status"
#       responseLength          = "$context.responseLength"
#       integrationErrorMessage = "$context.integrationErrorMessage"
#       }
#     )
#   }
# }

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.feedback_app.id}"
  parent_id   = "${aws_api_gateway_rest_api.feedback_app.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.feedback_app.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.feedback_app.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.feedback_app.invoke_arn}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.feedback_app.id}"
  resource_id   = "${aws_api_gateway_rest_api.feedback_app.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.feedback_app.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.feedback_app.invoke_arn}"
}

resource "aws_api_gateway_deployment" "feedback_app" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = "${aws_api_gateway_rest_api.feedback_app.id}"
  stage_name  = "p"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.feedback_app.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.feedback_app.execution_arn}/*/*"
}



//// Cloudwatch:
# variable "lambda_function_name" {
#   default = "feedback_app"
# }

# resource "aws_lambda_function" "test_lambda" {
#   function_name = var.lambda_function_name

#   # ... other configuration ...
#   depends_on = [
#     aws_iam_role_policy_attachment.lambda_logs,
#     aws_cloudwatch_log_group.feedback_app,
#   ]
# }

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "feedback_app" {
  name              = "/aws/lambda/${aws_lambda_function.feedback_app.function_name}"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}



// Output
output "base_url" {
  value = "${aws_api_gateway_deployment.feedback_app.invoke_url}"
}

//TODO.... https://learn.hashicorp.com/tutorials/terraform/lambda-api-gateway
//data "archive_file" "lambda_hello_world" {
//  type = "zip"
//
//  source_dir  = "${path.module}/hello-world"
//  output_path = "${path.module}/hello-world.zip"
// }



