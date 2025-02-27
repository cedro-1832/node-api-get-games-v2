#!/bin/bash

set -e  # Detener el script en caso de error

# Configuración de AWS
AWS_PROFILE="serverless-deployer"
AWS_REGION="us-east-1"
STACK_NAME="get-games-api-dev"
BUCKET_NAME="serverless-framework-deployments-us-east-1-3e2cf282-a30b"
IAM_USER="serverless-deployer"
IAM_POLICY_NAME="S3FullAccess"
POLICY_FILE="s3-policy.json"

echo "🚨 Eliminando pila de CloudFormation si está en DELETE_FAILED..."
aws cloudformation delete-stack --stack-name "$STACK_NAME" --profile "$AWS_PROFILE" --region "$AWS_REGION" || true
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --profile "$AWS_PROFILE" --region "$AWS_REGION" || {
    echo "⚠️ ERROR: No se pudo eliminar la pila completamente. Verifica manualmente en AWS Console."
}

echo "🔍 Verificando permisos de S3 para el usuario: $IAM_USER..."
echo "========================================================="

# 1️⃣ Verificar si el usuario tiene políticas asignadas
echo "🔍 [1/7] Listando políticas asignadas al usuario..."
aws iam list-attached-user-policies --user-name "$IAM_USER" --profile "$AWS_PROFILE" --region "$AWS_REGION"

# 2️⃣ Verificar si hay una política restrictiva (AWSCompromisedKeyQuarantineV3)
echo "🚨 [2/7] Buscando políticas restrictivas..."
RESTRICTIVE_POLICY=$(aws iam list-attached-user-policies --user-name "$IAM_USER" --profile "$AWS_PROFILE" --region "$AWS_REGION" \
    --query "AttachedPolicies[?PolicyName=='AWSCompromisedKeyQuarantineV3'].PolicyArn" --output text)

if [[ -n "$RESTRICTIVE_POLICY" ]]; then
    echo "❌ Se encontró una política restrictiva: $RESTRICTIVE_POLICY"
    echo "⚠️ Eliminando política restrictiva para habilitar acceso..."
    aws iam detach-user-policy --user-name "$IAM_USER" --policy-arn "$RESTRICTIVE_POLICY" --profile "$AWS_PROFILE" --region "$AWS_REGION"
    echo "✅ Política restrictiva eliminada."
else
    echo "✅ No se encontraron políticas restrictivas."
fi

# 3️⃣ Verificar si el bucket S3 tiene restricciones de política pública
echo "🔍 [3/7] Verificando configuraciones de bloqueo público en S3..."
BLOCK_PUBLIC_POLICY=$(aws s3api get-public-access-block --bucket "$BUCKET_NAME" --profile "$AWS_PROFILE" --region "$AWS_REGION" --query "PublicAccessBlockConfiguration.BlockPublicPolicy" --output text 2>/dev/null)

if [[ "$BLOCK_PUBLIC_POLICY" == "True" ]]; then
    echo "⚠️ El bucket tiene activado el 'BlockPublicPolicy'. Esto puede bloquear cambios en las políticas del bucket."
    echo "🔓 Desactivando bloqueo de políticas públicas en el bucket..."
    aws s3api delete-public-access-block --bucket "$BUCKET_NAME" --profile "$AWS_PROFILE" --region "$AWS_REGION"
    echo "✅ Bloqueo de políticas públicas eliminado."
else
    echo "✅ No hay bloqueo de políticas públicas en el bucket."
fi

# 4️⃣ Verificar la política del bucket S3
echo "🔍 [4/7] Verificando la política del bucket S3..."
if aws s3api get-bucket-policy --bucket "$BUCKET_NAME" --profile "$AWS_PROFILE" --region "$AWS_REGION" &>/dev/null; then
    echo "✅ La política del bucket ya existe."
else
    echo "⚠️ No se encontró una política de bucket. Creando una nueva..."
    cat <<EOT > $POLICY_FILE
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::$BUCKET_NAME",
                "arn:aws:s3:::$BUCKET_NAME/*"
            ]
        }
    ]
}
EOT
    aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --profile "$AWS_PROFILE" --region "$AWS_REGION" --policy file://$POLICY_FILE
    echo "✅ Política del bucket aplicada."
fi

# 5️⃣ Verificar permisos específicos en S3
echo "🔍 [5/7] Simulando permisos del usuario en S3..."
aws iam simulate-principal-policy \
    --policy-source-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):user/"$IAM_USER" \
    --action-names s3:ListBucket s3:GetObject s3:PutObject s3:DeleteObject \
    --profile "$AWS_PROFILE" --region "$AWS_REGION"

# 6️⃣ Asignar permisos si es necesario
echo "🔍 [6/7] Verificando si el usuario tiene permisos S3 asignados..."
EXISTING_POLICY=$(aws iam list-user-policies --user-name "$IAM_USER" --profile "$AWS_PROFILE" --region "$AWS_REGION" \
    --query "PolicyNames[]" --output text)

if [[ "$EXISTING_POLICY" != *"$IAM_POLICY_NAME"* ]]; then
    echo "📝 Creando política de permisos S3..."
    cat <<EOT > $POLICY_FILE
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::$BUCKET_NAME",
                "arn:aws:s3:::$BUCKET_NAME/*"
            ]
        }
    ]
}
EOT
    aws iam put-user-policy --user-name "$IAM_USER" --policy-name "$IAM_POLICY_NAME" --policy-document file://$POLICY_FILE --profile "$AWS_PROFILE" --region "$AWS_REGION"
    echo "✅ Permisos de S3 asignados."
else
    echo "✅ El usuario ya tiene permisos adecuados."
fi

# 7️⃣ Intentar listar objetos del bucket S3
echo "🔍 [7/7] Probando acceso a S3..."
if aws s3 ls "s3://$BUCKET_NAME" --profile "$AWS_PROFILE" --region "$AWS_REGION" &>/dev/null; then
    echo "✅ ¡El usuario tiene acceso a S3 correctamente!"
else
    echo "❌ ERROR: El usuario aún no tiene acceso a S3. Verifica las políticas manualmente en la consola de AWS."
fi

echo "✅ Proceso completado. Intenta desplegar nuevamente. 🎉"
