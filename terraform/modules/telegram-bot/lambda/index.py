import os
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.logging import correlation_paths
from aws_lambda_powertools.event_handler.api_gateway import ApiGatewayResolver
from aws_lambda_powertools.utilities import parameters
from telegram import Bot
from telegram.ext import Dispatcher


tracer = Tracer()
logger = Logger()
app = ApiGatewayResolver()  # by default API Gateway REST API (v1)
token = parameters.get_parameter(os.environ["TELEGRAM_TOKEN_PARAM"], decrypt=True)
webhook_url = os.environ["WEBHOOK_URL"]
bot = Bot(token)
dispatcher = Dispatcher(bot)


@app.post("/webhook")
@tracer.capture_method
def post_webhook():
    logger.info(app.current_event.json_body)
    return {
        "message": "hello"
    }


@logger.inject_lambda_context(correlation_id_path=correlation_paths.API_GATEWAY_REST)
@tracer.capture_lambda_handler
def handler(event, context):
    return app.resolve(event, context)

# api gateway support
# receive messages from api gateway
# store user credentials in dynamodb
# create events for spotify-scraper

# separate telegram-processor that can handle events from spotify-whatever? or user requested information such as backups?
