import os
from aws_lambda_powertools.utilities import parameters


parameter_prefix = os.environ.get("PARAMETER_PREFIX") or ""
bot_id = parameters.get_secret(f"{parameter_prefix}/telegram-bot/bot-id")
bot_token = parameters.get_secret(f"{parameter_prefix}/telegram-bot/bot-token")


def handler(evt, ctx):
    pass

# api gateway support
# receive messages from api gateway
# store user credentials in dynamodb
# create events for spotify-scraper

# separate telegram-processor that can handle events from spotify-whatever? or user requested information such as backups?
