#!/bin/bash
set -e  # Detener el script en caso de error

# 🏗 Configuración de AWS
AWS_REGION="us-east-1"
AWS_PROFILE="serverless-deployer"

echo "⚙️ Configurando AWS_PROFILE correctamente..."
export AWS_PROFILE="$AWS_PROFILE"

# Eliminar credenciales previas en caso de estar configuradas
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

# Verificar el usuario autenticado
CURRENT_USER=$(aws sts get-caller-identity --query 'Arn' --output text --profile "$AWS_PROFILE")

if [ -z "$CURRENT_USER" ]; then
  echo "❌ Error: No se pudo autenticar con AWS. Verifica que el perfil '$AWS_PROFILE' esté configurado correctamente en ~/.aws/credentials."
  exit 1
fi

echo "✅ AWS_PROFILE configurado como: $AWS_PROFILE"
echo "👤 Usuario autenticado: $CURRENT_USER"

# Guardar la configuración en ~/.zshrc o ~/.bash_profile para persistencia
if [ -n "$ZSH_VERSION" ]; then
  echo 'export AWS_PROFILE="serverless-deployer"' >> ~/.zshrc
  source ~/.zshrc
elif [ -n "$BASH_VERSION" ]; then
  echo 'export AWS_PROFILE="serverless-deployer"' >> ~/.bash_profile
  source ~/.bash_profile
fi

# 🔍 Verificar existencia del bucket S3
BUCKET_NAME="serverless-framework-deployments-us-east-1-$(aws sts get-caller-identity --query 'Account' --output text --profile "$AWS_PROFILE")"

echo "🔍 Verificando existencia del bucket S3: $BUCKET_NAME..."
if ! aws s3 ls "s3://$BUCKET_NAME" --profile "$AWS_PROFILE" --region "$AWS_REGION" &>/dev/null; then
    echo "⚠️ El bucket $BUCKET_NAME no existe. Creándolo..."
    aws s3 mb "s3://$BUCKET_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE"
    echo "✅ Bucket $BUCKET_NAME creado exitosamente."
else
    echo "✅ El bucket $BUCKET_NAME ya existe."
fi

# 🚀 Iniciar despliegue de la API en AWS
echo "🚀 Iniciando despliegue de la API Get Games en AWS..."

# Evitar conflictos en credenciales
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

# 🧹 Limpiar e instalar dependencias
rm -rf node_modules package-lock.json
npm cache clean --force
npm install --omit=dev

# 📦 Empaquetar archivos para el despliegue
mkdir -p dist
cp -r server.js package.json config controllers middlewares models routes dist/

cd dist
zip -r ../get-games.zip ./*
cd ..

export AWS_PROFILE="$AWS_PROFILE"

# 🔄 Ejecutar despliegue con Serverless
serverless deploy --stage dev --region "$AWS_REGION" --aws-profile "$AWS_PROFILE"

echo "🎉 Despliegue completado exitosamente 🚀"
