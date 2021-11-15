output "api_url" {
  value = aws_api_gateway_deployment.webhook.invoke_url
}

output "api_v1_webhook_url" {
  value = "${aws_api_gateway_stage.v1.invoke_url}${aws_api_gateway_resource.webhook.path}"
}
