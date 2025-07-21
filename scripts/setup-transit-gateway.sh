#!/bin/bash
set -euo pipefail

source .env

if [[ -z "${AWS_ACCOUNT_ID:-}" || -z "${AWS_REGION:-}" ]]; then
  echo "AWS_ACCOUNT_ID and AWS_REGION must be set in .env" >&2
  exit 1
fi

STACK_NAME="dev-noderunners-${USER}-PrivateChainCommonInfra"
VPC_ID=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?ExportName=='FleetVpcId'].OutputValue" \
  --region "$AWS_REGION" --output text)

if [[ -z "$VPC_ID" || "$VPC_ID" == "None" ]]; then
  echo "Could not determine VPC ID from stack $STACK_NAME" >&2
  exit 1
fi

if [[ -z "${TGW_ID:-}" || "$TGW_ID" == "" ]]; then
  TGW_ID=$(aws ec2 create-transit-gateway \
    --description "PrivateChain TGW" \
    --region "$AWS_REGION" \
    --query 'TransitGateway.TransitGatewayId' --output text)
  echo "Created Transit Gateway $TGW_ID"
fi

SUBNET_IDS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID --query 'Subnets[].SubnetId' --region "$AWS_REGION" --output text)
ATTACH_ID=$(aws ec2 create-transit-gateway-vpc-attachment \
  --transit-gateway-id "$TGW_ID" \
  --vpc-id "$VPC_ID" \
  --subnet-ids $SUBNET_IDS \
  --region "$AWS_REGION" \
  --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' --output text)

echo "Created attachment $ATTACH_ID"

if [[ -n "${INVITED_ACCOUNT_IDS:-}" ]]; then
  ACCOUNTS=$(echo "$INVITED_ACCOUNT_IDS" | tr ',' ' ')
  SHARE_ARN=$(aws ram create-resource-share \
    --name PrivateChainTGWShare \
    --resource-arns arn:aws:ec2:$AWS_REGION:$AWS_ACCOUNT_ID:transit-gateway/$TGW_ID \
    --principals $ACCOUNTS \
    --allow-external-principals \
    --region "$AWS_REGION" \
    --query 'resourceShare.arn' --output text)
  echo "Shared TGW via $SHARE_ARN with accounts: $ACCOUNTS"
fi

echo "TGW setup complete. Use TGW_ID=$TGW_ID for additional accounts"
