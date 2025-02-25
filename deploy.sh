#!/bin/bash

set -e  # Detener el script en caso de error

AWS_REGION="us-east-1"
AWS_PROFILE="serverless-deployer"
STACK_NAME="get-games-api"
IAM_ROLE_NAME="get-games-api-lambda-role"
FUNCTION_NAME="get-games"
DEPLOY_DIR="dist"

echo "🚀 Iniciando despliegue de la API Get Games en AWS..."

# 📦 Instalando dependencias...
rm -rf .serverless/ node_modules package-lock.json get-games.zip
npm install --omit=dev
npm install serverless-http

# 🏗️ Construir la aplicación
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"
cp -r server.js package.json config controllers middlewares models routes "$DEPLOY_DIR"

# 📤 Empaquetar código para AWS Lambda
cd "$DEPLOY_DIR"
zip -r "../$FUNCTION_NAME.zip" ./* -x "node_modules/aws-sdk/**"
cd ..

# 🔍 Obtener ARN del IAM Role
IAM_ROLE_ARN=$(aws iam get-role --role-name "$IAM_ROLE_NAME" --query 'Role.Arn' --output text --region "$AWS_REGION" --profile "$AWS_PROFILE" || echo "")

if [ -z "$IAM_ROLE_ARN" ]; then
    echo "❌ Error: No se pudo obtener el ARN del IAM Role. Creando rol IAM..."
    
    aws iam create-role --role-name "$IAM_ROLE_NAME" \
        --assume-role-policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": { "Service": "lambda.amazonaws.com" },
                    "Action": "sts:AssumeRole"
                }
            ]
        }' --region "$AWS_REGION" --profile "$AWS_PROFILE"

    aws iam attach-role-policy --role-name "$IAM_ROLE_NAME" \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
        --region "$AWS_REGION" --profile "$AWS_PROFILE"

    echo "✅ IAM Role creado correctamente."
else
    echo "✅ IAM Role ya existe."
fi

# 🔥 Desplegar API Gateway con Serverless Framework
serverless deploy --stage dev --region "$AWS_REGION" --aws-profile "$AWS_PROFILE"
