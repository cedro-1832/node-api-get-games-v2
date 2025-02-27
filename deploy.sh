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

# 🔍 Verificar permisos antes de proceder
echo "🔍 Verificando permisos de S3..."
if ! aws s3 ls "s3://serverless-framework-deployments-us-east-1-3e2cf282-a30b" --region "$AWS_REGION" --profile "$AWS_PROFILE" &>/dev/null; then
    echo "❌ Error: No tienes permisos en S3. Verifica la política IAM."
    exit 1
fi

# 🏗️ Construir la aplicación
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"
cp -r server.js package.json config controllers middlewares models routes "$DEPLOY_DIR"

# 📤 Empaquetar código para AWS Lambda
cd "$DEPLOY_DIR"
zip -r "../$FUNCTION_NAME.zip" ./* -x "node_modules/aws-sdk/**"
cd ..

# 🔥 Desplegar API Gateway con Serverless Framework
serverless deploy --debug --stage dev --region "$AWS_REGION" --aws-profile "$AWS_PROFILE"
