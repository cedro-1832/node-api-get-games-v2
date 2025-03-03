#!/bin/bash
set -e  # Detener el script en caso de error

AWS_REGION="us-east-1"
AWS_PROFILE="serverless-deployer"
BUCKET_NAME="serverless-framework-deployments-us-east-1-$(aws sts get-caller-identity --query 'Account' --output text)"

export AWS_PROFILE="serverless-deployer"  # Usa el perfil AWS configurado en ~/.aws/credentials


echo "🔍 Verificando existencia del bucket S3: $BUCKET_NAME..."
if ! aws s3 ls "s3://$BUCKET_NAME" --profile "$AWS_PROFILE" --region "$AWS_REGION" &>/dev/null; then
    echo "⚠️ El bucket $BUCKET_NAME no existe. Creándolo..."
    aws s3 mb "s3://$BUCKET_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE"
    echo "✅ Bucket $BUCKET_NAME creado exitosamente."
else
    echo "✅ El bucket $BUCKET_NAME ya existe."
fi

echo "🚀 Iniciando despliegue de la API Get Games en AWS..."

# Evitar conflictos en credenciales
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

# Limpiar e instalar dependencias sin paquetes obsoletos
rm -rf node_modules package-lock.json
npm cache clean --force
npm install --omit=dev

mkdir -p dist
cp -r server.js package.json config controllers middlewares models routes dist/

cd dist
zip -r ../get-games.zip ./*
cd ..

export AWS_PROFILE=default

serverless deploy --stage dev --region "$AWS_REGION" --aws-profile "$AWS_PROFILE"
