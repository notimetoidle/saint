resource "aws_iam_role" "lambda_main" {
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

resource "aws_iam_role_policy" "lambda_main_logs" {
  name = "${var.name}-logs"
  role = aws_iam_role.lambda_main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:PutLogEvents",
        "logs:CreateLogStream"
      ]
      Effect   = "Allow"
      Resource = "${aws_cloudwatch_log_group.lambda_main.arn}:*"
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

resource "aws_iam_role_policy" "lambda_main_ssm" {
  name = "${var.name}-ssm"
  role = aws_iam_role.lambda_main.id

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

resource "aws_cloudwatch_log_group" "lambda_main" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 30
}

data "archive_file" "lambda_main" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${var.build_dir}/${var.name}-main.zip"
}

resource "aws_lambda_function" "main" {
  function_name = var.name

  filename         = data.archive_file.lambda_main.output_path
  role             = aws_iam_role.lambda_main.arn
  handler          = var.handler
  runtime          = var.runtime
  source_code_hash = data.archive_file.lambda_main.output_base64sha256
  memory_size      = var.memory_size
  layers           = var.layers
  timeout          = 30

  environment {
    variables = {
      TELEGRAM_TOKEN_PARAM = var.token_param
      WEBHOOK_URL          = var.webhook_url
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_main]
}

data "aws_lambda_invocation" "main" {
  function_name = aws_lambda_function.main.function_name
  input         = jsonencode({})
}
