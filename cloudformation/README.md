# saint

## cloudformation

### [apigw-settings.yaml](./apigw-settings.yaml)

#### Description

Prepares the AWS account's regional API gateway settings for logging to CloudWatch. Mostly used for debugging as of writing.

If such settings are already in place, deployment of this stack is not necessary.

Created resources:
- IAM role that allows all API gateways in the region to push logs to CloudWatch
- API gateway account setting to start using the created IAM role

Docs:
- <https://aws.amazon.com/premiumsupport/knowledge-center/api-gateway-cloudwatch-logs/>

#### Deployment

Via AWS CLI:

```sh
aws cloudformation deploy --stack-name apigw-settings --template-file ./apigw-settings.yaml --capabilities CAPABILITY_NAMED_IAM
```
#### Deletion

Via AWS CLI:

```sh
aws cloudformation delete-stack --stack-name apigw-settings
```
