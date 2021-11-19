import os
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities import parameters
from telegram import Bot


tracer = Tracer()
logger = Logger()
token = parameters.get_parameter(os.environ["TELEGRAM_TOKEN_PARAM"], decrypt=True)
webhook_url = os.environ["WEBHOOK_URL"]
bot = Bot(token)


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def handler(event, context):
    logger.info("Setting webhook URL")
    return bot.set_webhook(
        url=webhook_url,
        max_connections=5
    )
