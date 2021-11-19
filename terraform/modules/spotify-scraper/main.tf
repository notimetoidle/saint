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

locals {
  lambda_main_name = var.name
}

resource "aws_cloudwatch_log_group" "lambda_main" {
  name              = "/aws/lambda/${local.lambda_main_name}"
  retention_in_days = 30
}

data "archive_file" "lambda_main" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${var.build_dir}/${var.name}-main.zip"
}

resource "aws_lambda_function" "main" {
  function_name = local.lambda_main_name

  filename         = data.archive_file.lambda_main.output_path
  role             = aws_iam_role.lambda_main.arn
  handler          = var.handler
  runtime          = var.runtime
  source_code_hash = data.archive_file.lambda_main.output_base64sha256
  memory_size      = var.memory_size
  layers           = var.layers

  depends_on = [aws_cloudwatch_log_group.lambda_main]
}
