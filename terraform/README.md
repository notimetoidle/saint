# saint

## terraform

Various Terraform modules

### [modules](./modules/README.md)

Custom submodules used in this project

### root module

The root module is what is deployed by the user, with various optional variables

#### deployment

Deploy stacks

```sh
terraform plan -out terraform.tfplan
terraform apply terraform.tfplan
```

Set Telegram bot API token

```sh
aws ssm put-parameter \
    --name /saint/telegram/token \
    --value $(cat telegram_token | tr -d '\n') \
    --type SecureString \
    --overwrite
```
Tell Telegram your webhook URL

```sh
terraform output -raw telegram_bot_api_v1_webhook_url
```
