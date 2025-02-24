#!/bin/bash

set -e  # Detener el script en caso de error

AWS_REGION="us-east-1"
AWS_PROFILE="serverless-deployer"
STACK_NAME="get-games-api"
IAM_ROLE_NAME="get-games-api-lambda-role"
FUNCTION_NAME="get-games"
DEPLOY_DIR="dist"

echo "🚀 Iniciando despliegue de la API Get Games en AWS..."

# 🛠️ Instalar dependencias asegurando serverless-http
echo "📦 Instalando dependencias..."
rm -rf node_modules package-lock.json .serverless/ get-games.zip
npm install --omit=dev
npm install serverless-http  # 🔴 Asegurar instalación de serverless-http

# 🗑️ Eliminar archivos innecesarios
echo "🗑️ Eliminando archivos innecesarios..."
find . -name "*.zip" -type f -delete
find . -name "*.log" -type f -delete
rm -rf .serverless/ node_modules/.bin/ tests/ docs/ node_modules/aws-sdk/

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

# 🔍 Verificar si la función Lambda ya existe
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

# 🔥 Desplegar API Gateway con Serverless Framework
echo "🌐 Desplegando API Gateway con Serverless..."
serverless deploy --stage dev --region "$AWS_REGION" --aws-profile "$AWS_PROFILE"

# 📌 Obtener la URL de la API Gateway correctamente
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
