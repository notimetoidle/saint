module "spotify_processor" {
  source = "./modules/spotify-processor"

  name = "${var.name}-spotify-processor"
  layers = [
    aws_lambda_layer_version.python_telegram_bot.arn
  ]
  runtime   = var.runtime
  build_dir = "${path.root}/../build"
}

module "spotify_scraper" {
  source = "./modules/spotify-scraper"

  name = "${var.name}-spotify-scraper"
  layers = [
    aws_lambda_layer_version.aws_lambda_powertools.arn,
    aws_lambda_layer_version.spotipy.arn
  ]
  runtime   = var.runtime
  build_dir = "${path.root}/../build"
}

module "telegram_bot" {
  source = "./modules/telegram-bot"

  name = "${var.name}-telegram-bot"
  layers = [
    aws_lambda_layer_version.aws_lambda_powertools.arn,
    aws_lambda_layer_version.python_telegram_bot.arn
  ]
  runtime     = var.runtime
  build_dir   = "${path.root}/../build"
  token_param = var.telegram_bot_token_param
}

module "telegram_registration" {
  source = "./modules/telegram-registration"

  name = "${var.name}-telegram-registration"
  layers = [
    aws_lambda_layer_version.aws_lambda_powertools.arn,
    aws_lambda_layer_version.python_telegram_bot.arn
  ]
  runtime     = var.runtime
  build_dir   = "${path.root}/../build"
  token_param = var.telegram_bot_token_param
  webhook_url = module.telegram_bot.api_v1_webhook_url
}

output "telegram_bot_api_url" {
  value = module.telegram_bot.api_url
}

output "telegram_bot_api_v1_webhook_url" {
  value = module.telegram_bot.api_v1_webhook_url
}
