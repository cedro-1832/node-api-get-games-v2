#!/bin/bash

set -e  # Detener el script en caso de error

AWS_PROFILE="serverless-deployer"
AWS_REGION="us-east-1"
STACK_NAME="get-games-api-dev"
BUCKET_NAME="serverless-framework-deployments-us-east-1-3e2cf282-a30b"
IAM_USER="serverless-deployer"
IAM_POLICY_NAME="S3FullAccess"
POLICY_FILE="s3-policy.json"

echo "🔍 Verificando existencia del bucket S3: $BUCKET_NAME..."
if ! aws s3 ls "s3://$BUCKET_NAME" --profile "$AWS_PROFILE" --region "$AWS_REGION" &>/dev/null; then
    echo "⚠️ El bucket $BUCKET_NAME no existe. Creándolo..."
    aws s3 mb "s3://$BUCKET_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE"
    echo "✅ Bucket $BUCKET_NAME creado exitosamente."
else
    echo "✅ El bucket $BUCKET_NAME ya existe."
fi
