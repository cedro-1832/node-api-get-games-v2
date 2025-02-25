#!/bin/bash

set -e  # Detener el script en caso de error

AWS_REGION="us-east-1"
AWS_PROFILE="serverless-deployer"
STACK_NAME="get-games-api"
IAM_ROLE_NAME="get-games-api-lambda-role"
FUNCTION_NAME="get-games"
DEPLOY_DIR="dist"

echo "🚀 Iniciando despliegue de la API Get Games en AWS..."

# 🛠️ Limpiar caché y reinstalar dependencias
echo "📦 Limpiando caché y reinstalando dependencias..."
rm -rf .serverless/ node_modules package-lock.json get-games.zip
npm install --omit=dev
npm install serverless-http  # 🔴 Asegurar instalación de serverless-http

# 🏗️ Construir la aplicación
echo "🔧 Construyendo el proyecto..."
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"
cp -r server.js package.json config controllers middlewares models routes "$DEPLOY_DIR"

# 📤 Empaquetar código para AWS Lambda
echo "📤 Empaquetando código para AWS Lambda..."
cd "$DEPLOY_DIR"
zip -r "../$FUNCTION_NAME.zip" ./* -x "node_modules/aws-sdk/**"
cd ..

# 🔍 Verificar si el IAM Role existe antes de crearlo
echo "🔍 Verificando si el IAM Role $IAM_ROLE_NAME existe..."
if ! aws iam get-role --role-name "$IAM_ROLE_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" &>/dev/null; then
    echo "🚀 Creando IAM Role para Lambda..."
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
        }' \
        --region "$AWS_REGION" --profile "$AWS_PROFILE"

    aws iam attach-role-policy --role-name "$IAM_ROLE_NAME" \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
        --region "$AWS_REGION" --profile "$AWS_PROFILE"
    
    echo "✅ IAM Role creado y configurado."
else
    echo "✅ IAM Role ya existe."
fi

# 🔍 Obtener ARN del IAM Role
IAM_ROLE_ARN=$(aws iam get-role --role-name "$IAM_ROLE_NAME" --query 'Role.Arn' --output text --region "$AWS_REGION" --profile "$AWS_PROFILE")

echo "✅ Desplegando con Serverless..."
serverless deploy --stage dev --region "$AWS_REGION" --aws-profile "$AWS_PROFILE"
