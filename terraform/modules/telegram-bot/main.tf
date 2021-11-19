# api gateway
# register with telegram?
#

resource "aws_api_gateway_rest_api" "main" {
  name = var.name
}

resource "aws_api_gateway_resource" "webhook" {
  path_part   = "webhook"
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.main.id
}

resource "aws_api_gateway_method" "webhook_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.webhook.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "webhook_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.webhook.id
  http_method             = aws_api_gateway_method.webhook_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.webhook.invoke_arn
}

resource "aws_api_gateway_deployment" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.webhook.id,
      aws_api_gateway_method.webhook_post.id,
      aws_api_gateway_integration.webhook_lambda.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "main_v1" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.main.id}/v1"
  retention_in_days = 30
}

resource "aws_api_gateway_stage" "v1" {
  depends_on    = [aws_cloudwatch_log_group.main_v1]
  deployment_id = aws_api_gateway_deployment.webhook.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "v1"
}

resource "aws_api_gateway_method_settings" "v1_all" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.v1.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = false
    logging_level          = "ERROR"
    throttling_burst_limit = 10
    throttling_rate_limit  = 5
  }
}

resource "aws_iam_role" "lambda_webhook" {
  name = var.name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_webhook_logs" {
  name = "${var.name}-logs"
  role = aws_iam_role.lambda_webhook.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:PutLogEvents",
        "logs:CreateLogStream"
      ]
      Effect   = "Allow"
      Resource = "${aws_cloudwatch_log_group.lambda_webhook.arn}:*"
    }]
  })
}

# By using these two data sources to construct the token param ARN instead of aws_ssm_parameter
# we are avoiding having the Telegram token secret being stored in the state file as plain text
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter
data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  token_param_arn = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${trimprefix(var.token_param, "/")}"
  ssm_key_arn     = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alias/aws/ssm"
}

resource "aws_iam_role_policy" "lambda_webhook_ssm" {
  name = "${var.name}-ssm"
  role = aws_iam_role.lambda_webhook.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      # https://docs.aws.amazon.com/service-authorization/latest/reference/list_awssystemsmanager.html
      Action = [
        "ssm:GetParameter"
      ]
      Effect   = "Allow"
      Resource = local.token_param_arn
      }, {
      # https://docs.aws.amazon.com/service-authorization/latest/reference/list_awskeymanagementservice.html
      # https://docs.aws.amazon.com/kms/latest/developerguide/services-parameter-store.html#parameter-store-encryption-context
      Action = [
        "kms:Decrypt"
      ]
      Effect   = "Allow"
      Resource = local.ssm_key_arn
      Condition = {
        StringEquals = {
          "kms:EncryptionContext:PARAMETER_ARN" = local.token_param_arn
        }
      }
    }]
  })
}

locals {
  lambda_webhook_name = var.name
}

resource "aws_cloudwatch_log_group" "lambda_webhook" {
  name              = "/aws/lambda/${local.lambda_webhook_name}"
  retention_in_days = 30
}

data "archive_file" "lambda_webhook" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${var.build_dir}/${var.name}-webhook.zip"
}

resource "aws_lambda_function" "webhook" {
  function_name = local.lambda_webhook_name

  filename         = data.archive_file.lambda_webhook.output_path
  role             = aws_iam_role.lambda_webhook.arn
  handler          = var.handler
  runtime          = var.runtime
  source_code_hash = data.archive_file.lambda_webhook.output_base64sha256
  memory_size      = var.memory_size
  layers           = var.layers

  environment {
    variables = {
      TELEGRAM_TOKEN_PARAM = var.token_param
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_webhook]
}

resource "aws_lambda_permission" "apigw_webhook" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webhook.function_name
  principal     = "apigateway.amazonaws.com"
  # https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_stage.v1.execution_arn}/${aws_api_gateway_method.webhook_post.http_method}${aws_api_gateway_resource.webhook.path}"
}


# TODO
# multiple part path /v1/webhook/update
# working throttling
