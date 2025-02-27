#!/bin/bash

set -e  # Detener el script en caso de error

AWS_REGION="us-east-1"
AWS_PROFILE="serverless-deployer"

echo "🚀 Iniciando despliegue de la API Get Games en AWS..."

# 📦 Instalando dependencias...
rm -rf node_modules package-lock.json
npm cache clean --force
npm install --omit=dev

# 📤 Empaquetar código para AWS Lambda
mkdir -p dist
cp -r server.js package.json config controllers middlewares models routes dist/

cd dist
zip -r ../get-games.zip ./*
cd ..

# 🔥 Desplegar API Gateway con Serverless Framework sin especificar bucket
serverless deploy --debug --stage dev --region "$AWS_REGION" --aws-profile "$AWS_PROFILE"
