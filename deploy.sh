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

# 🗑️ Eliminar archivos innecesarios
echo "🗑️ Eliminando archivos innecesarios..."
find . -name "*.zip" -type f -delete
find . -name "*.log" -type f -delete
rm -rf .serverless/ node_modules/.bin/ tests/ docs/ node_modules/aws-sdk/

# 🔍 Verificar si el IAM Role existe
echo "🔍 Verificando si el IAM Role $IAM_ROLE_NAME existe..."
IAM_ROLE_EXISTS=$(aws iam get-role --role-name "$IAM_ROLE_NAME" --query 'Role.RoleName' --output text --region "$AWS_REGION" --profile "$AWS_PROFILE" || true)

if [[ -z "$IAM_ROLE_EXISTS" ]]; then
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

    # Asignar permisos al role
    aws iam attach-role-policy --role-name "$IAM_ROLE_NAME" \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
        --region "$AWS_REGION" --profile "$AWS_PROFILE"
    
    echo "✅ IAM Role creado y configurado."
else
    echo "✅ IAM Role ya existe."
fi


echo "✅ Función Lambda lista."

# 🔥 Desplegar API Gateway con Serverless Framework
echo "🌐 Desplegando API Gateway con Serverless..."
serverless deploy --stage dev --region "$AWS_REGION" --aws-profile "$AWS_PROFILE"
