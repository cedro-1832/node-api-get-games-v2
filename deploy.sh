#!/bin/bash

set -e  # Detener el script en caso de error

AWS_REGION="us-east-1"
AWS_PROFILE="serverless-deployer"

echo "🚀 Iniciando despliegue de la API Get Games en AWS..."

# 📦 Instalando dependencias...
rm -rf .serverless/ node_modules package-lock.json
npm cache clean --force
npm install --omit=dev

# 🔍 Verificando permisos antes de proceder
if ! aws s3 ls "s3://serverless-framework-deployments-us-east-1-3e2cf282-a30b" --region "$AWS_REGION" --profile "$AWS_PROFILE" &>/dev/null; then
    echo "❌ Error: No tienes permisos en S3. Verifica la política IAM."
    exit 1
fi

# 📤 Empaquetar código para AWS Lambda
mkdir -p dist
cp -r server.js package.json config controllers middlewares models routes dist/

cd dist
zip -r ../get-games.zip ./*
cd ..

# 🔥 Desplegar API Gateway con Serverless Framework
serverless deploy --debug --stage dev --region "$AWS_REGION" --aws-profile "$AWS_PROFILE"
