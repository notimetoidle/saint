data "archive_file" "layer_aws_lambda_powertools" {
  type        = "zip"
  source_dir  = "${path.root}/../lambda-layers/aws-lambda-powertools"
  output_path = "${path.root}/../build/layer-aws-lambda-powertools.zip"
}

resource "aws_lambda_layer_version" "aws_lambda_powertools" {
  filename                 = data.archive_file.layer_aws_lambda_powertools.output_path
  source_code_hash         = data.archive_file.layer_aws_lambda_powertools.output_base64sha256
  layer_name               = "${var.name}-aws-lambda-powertools"
  compatible_runtimes      = [var.runtime]
  compatible_architectures = [var.architecture]
}

data "archive_file" "layer_python_telegram_bot" {
  type        = "zip"
  source_dir  = "${path.root}/../lambda-layers/python-telegram-bot"
  output_path = "${path.root}/../build/layer-python-telegram-bot.zip"
}

resource "aws_lambda_layer_version" "python_telegram_bot" {
  filename                 = data.archive_file.layer_python_telegram_bot.output_path
  source_code_hash         = data.archive_file.layer_python_telegram_bot.output_base64sha256
  layer_name               = "${var.name}-python-telegram-bot"
  compatible_runtimes      = [var.runtime]
  compatible_architectures = [var.architecture]
}

data "archive_file" "layer_spotipy" {
  type        = "zip"
  source_dir  = "${path.root}/../lambda-layers/spotipy"
  output_path = "${path.root}/../build/layer-spotipy.zip"
}

resource "aws_lambda_layer_version" "spotipy" {
  filename                 = data.archive_file.layer_spotipy.output_path
  source_code_hash         = data.archive_file.layer_spotipy.output_base64sha256
  layer_name               = "${var.name}-spotipy"
  compatible_runtimes      = [var.runtime]
  compatible_architectures = [var.architecture]
}
