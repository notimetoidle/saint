from re import I
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.logging import correlation_paths
from aws_lambda_powertools.event_handler.api_gateway import ApiGatewayResolver
# from aws_lambda_powertools.utilities import parameters


# parameter_prefix = os.environ.get("PARAMETER_PREFIX") or ""
# bot_id = parameters.get_secret(f"{parameter_prefix}/telegram-bot/bot-id")
# bot_token = parameters.get_secret(f"{parameter_prefix}/telegram-bot/bot-token")

tracer = Tracer()
logger = Logger()
app = ApiGatewayResolver()  # by default API Gateway REST API (v1)


@app.post("/webhook")
def post_webhook():
    logger.info(app.current_event)
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
