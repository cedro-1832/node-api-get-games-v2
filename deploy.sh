#!/bin/bash

set -e  # Detener el script en caso de error

AWS_REGION="us-east-1"
AWS_PROFILE="serverless-deployer"
STACK_NAME="get-games-api"
IAM_ROLE_NAME="get-games-api-lambda-role"
FUNCTION_NAME="get-games"
DEPLOY_DIR="dist"

echo "🚀 [1/9] Iniciando despliegue de la API Get Games en AWS..."

# 🛠️ [2/9] Instalar dependencias asegurando serverless-http
echo "📦 Instalando dependencias de producción..."
rm -rf node_modules package-lock.json .serverless/ get-games.zip
npm install --omit=dev  # Evitar dependencias de desarrollo
npm install serverless-http  # 🔴 Asegurar que serverless-http está instalado

# 🗑️ [3/9] Eliminando archivos innecesarios
echo "🗑️ Eliminando archivos innecesarios para reducir el tamaño del paquete..."
find . -name "*.zip" -type f -delete
find . -name "*.log" -type f -delete
rm -rf .serverless/ node_modules/.bin/

# 🏗️ [4/9] Construir la aplicación
echo "🔧 Construyendo el proyecto..."
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"
cp -r server.js package.json node_modules config controllers middlewares models routes "$DEPLOY_DIR"

# 📤 [5/9] Empaquetar código para AWS Lambda
echo "📤 Empaquetando código para AWS Lambda..."
cd "$DEPLOY_DIR"
zip -r "../$FUNCTION_NAME.zip" ./*
cd ..

# 🔍 [6/9] Verificar si el IAM Role existe, si no, crearlo
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

    # Asignar permisos al role
    aws iam attach-role-policy --role-name "$IAM_ROLE_NAME" \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
        --region "$AWS_REGION" --profile "$AWS_PROFILE"
    
    echo "✅ IAM Role creado y configurado."
else
    echo "✅ IAM Role ya existe."
fi

# 🔍 Obtener ARN del role
IAM_ROLE_ARN=$(aws iam get-role --role-name "$IAM_ROLE_NAME" --query 'Role.Arn' --output text --region "$AWS_REGION" --profile "$AWS_PROFILE")

# 🔍 [7/9] Verificar si la función Lambda ya existe
echo "🔍 Verificando si la función Lambda $FUNCTION_NAME existe en AWS..."
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" &>/dev/null; then
    echo "📤 Actualizando código de la función Lambda..."
    aws lambda update-function-code --function-name "$FUNCTION_NAME" \
        --zip-file "fileb://$FUNCTION_NAME.zip" \
        --region "$AWS_REGION" --profile "$AWS_PROFILE"
else
    echo "🚀 Creando nueva función Lambda..."
    aws lambda create-function --function-name "$FUNCTION_NAME" \
        --runtime "nodejs20.x" \
        --role "$IAM_ROLE_ARN" \
        --handler "server.handler" \
        --zip-file "fileb://$FUNCTION_NAME.zip" \
        --timeout 15 \
        --memory-size 128 \
        --region "$AWS_REGION" --profile "$AWS_PROFILE"
fi

echo "✅ Función Lambda lista."

# 🔥 [8/9] Desplegar API Gateway con Serverless Framework
echo "🌐 Desplegando API Gateway con Serverless..."
serverless deploy --stage dev --region "$AWS_REGION" --aws-profile "$AWS_PROFILE"

# 📌 [9/9] Obtener la URL de la API Gateway correctamente
echo "🔍 Obteniendo la URL de la API Gateway..."
API_ID=$(aws apigateway get-rest-apis --region "$AWS_REGION" --profile "$AWS_PROFILE" \
    --query "items[?contains(name, '$STACK_NAME')].id" --output text)

if [[ -z "$API_ID" ]]; then
    echo "❌ Error: No se pudo obtener el ID de la API Gateway."
    exit 1
else
    API_URL="https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/dev"
    echo "✅ API desplegada exitosamente: $API_URL"
fi
