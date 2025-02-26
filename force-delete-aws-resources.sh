#!/bin/bash

set -e  # Detener el script si ocurre un error

AWS_PROFILE="serverless-deployer"
AWS_REGION="us-east-1"
STACK_NAME="get-games-api-dev"
BUCKET_NAME="serverless-framework-deployments-us-east-1-3e2cf282-a30b"
IAM_ROLE="get-games-api-dev-lambdaRole"

echo "🚨 [1/11] Iniciando eliminación forzada de recursos en AWS..."

# 🔍 [2/11] Verificar si el S3 Bucket existe
echo "🔍 [2/11] Verificando existencia del S3 Bucket: $BUCKET_NAME..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" --profile $AWS_PROFILE --region $AWS_REGION 2>/dev/null; then
    echo "🗑️ [3/11] Eliminando todos los objetos y versiones del S3 Bucket..."

    OBJECT_VERSIONS=$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --profile $AWS_PROFILE --region $AWS_REGION --query "[Versions, DeleteMarkers][].{Key: Key, VersionId: VersionId}" --output json)

    echo "$OBJECT_VERSIONS" | jq -c '.[] | select(.Key != null)' | while read -r object; do
        KEY=$(echo "$object" | jq -r '.Key')
        VERSION_ID=$(echo "$object" | jq -r '.VersionId')
        aws s3api delete-object --bucket "$BUCKET_NAME" --key "$KEY" --version-id "$VERSION_ID" --profile $AWS_PROFILE --region $AWS_REGION
        echo "🗑️ Eliminado: $KEY (version: $VERSION_ID)"
    done

    # Eliminar el bucket vacío
    echo "🗑️ Eliminando el S3 Bucket: $BUCKET_NAME..."
    aws s3 rb "s3://$BUCKET_NAME" --profile $AWS_PROFILE --region $AWS_REGION || true
    echo "✅ S3 Bucket eliminado."
else
    echo "⚠️ Bucket no encontrado. Saltando pasos relacionados con S3..."
fi

# 🔥 [4/11] Verificar y eliminar funciones Lambda bloqueadas
echo "🔥 [4/11] Eliminando funciones Lambda bloqueadas..."
LAMBDA_FUNCTIONS=("get-games-api-dev-getGames" "get-games-api-dev-login")

for FUNCTION in "${LAMBDA_FUNCTIONS[@]}"; do
    echo "🔍 Verificando función Lambda: $FUNCTION..."
    if aws lambda get-function --function-name "$FUNCTION" --profile $AWS_PROFILE --region $AWS_REGION &>/dev/null; then
        aws lambda delete-function --function-name "$FUNCTION" --profile $AWS_PROFILE --region $AWS_REGION
        echo "✅ Función Lambda $FUNCTION eliminada."
    else
        echo "⚠️ Función Lambda $FUNCTION no encontrada."
    fi
done

# 🚀 [5/11] Verificar y eliminar Role IAM bloqueado
echo "🚀 [5/11] Eliminando Role IAM: $IAM_ROLE..."

# Obtener y eliminar políticas adjuntas
ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name "$IAM_ROLE" --profile $AWS_PROFILE --query "AttachedPolicies[].PolicyArn" --output text || true)

if [[ -n "$ATTACHED_POLICIES" ]]; then
    echo "🔍 Encontradas políticas adjuntas. Eliminando..."
    for POLICY_ARN in $ATTACHED_POLICIES; do
        echo "🗑️ Desasociando política: $POLICY_ARN"
        aws iam detach-role-policy --role-name "$IAM_ROLE" --policy-arn "$POLICY_ARN" --profile $AWS_PROFILE || true
    done
fi

# Obtener y eliminar políticas en línea
INLINE_POLICIES=$(aws iam list-role-policies --role-name "$IAM_ROLE" --profile $AWS_PROFILE --query "PolicyNames[]" --output text || true)

if [[ -n "$INLINE_POLICIES" ]]; then
    echo "🔍 Encontradas políticas en línea. Eliminando..."
    for POLICY_NAME in $INLINE_POLICIES; do
        echo "🗑️ Eliminando política en línea: $POLICY_NAME"
        aws iam delete-role-policy --role-name "$IAM_ROLE" --policy-name "$POLICY_NAME" --profile $AWS_PROFILE || true
    done
fi

# Intentar eliminar el Role IAM
if aws iam get-role --role-name "$IAM_ROLE" --profile $AWS_PROFILE &>/dev/null; then
    aws iam delete-role --role-name "$IAM_ROLE" --profile $AWS_PROFILE || true
    echo "✅ Role IAM eliminado."
else
    echo "⚠️ Role IAM no encontrado."
fi

# 🔥 [6/11] Verificar y eliminar API Gateway
echo "⚠️ [6/11] Eliminando API Gateway..."
APIGATEWAY_ID=$(aws apigateway get-rest-apis --profile $AWS_PROFILE --query "items[?name=='$STACK_NAME'].id" --output text || true)
if [[ ! -z "$APIGATEWAY_ID" ]]; then
    aws apigateway delete-rest-api --rest-api-id $APIGATEWAY_ID --profile $AWS_PROFILE
    echo "✅ API Gateway eliminado."
else
    echo "⚠️ No se encontró API Gateway para eliminar."
fi

# 🔥 [7/11] Forzar eliminación de la pila CloudFormation
echo "🔥 [7/11] Eliminando la pila CloudFormation: $STACK_NAME..."
aws cloudformation delete-stack --stack-name "$STACK_NAME" --profile $AWS_PROFILE || true

echo "⏳ [8/11] Esperando que la pila CloudFormation se elimine completamente..."
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --profile $AWS_PROFILE || {
    echo "⚠️ ERROR: La pila sigue en estado DELETE_FAILED. Intentando forzar eliminación..."

    # 🔍 [9/11] Buscar recursos bloqueados en la pila
    echo "🔍 [9/11] Buscando recursos bloqueados en la pila..."
    BLOCKED_RESOURCES=$(aws cloudformation describe-stack-resources \
        --stack-name "$STACK_NAME" \
        --profile $AWS_PROFILE \
        --query "StackResources[?ResourceStatus=='DELETE_FAILED'].PhysicalResourceId" \
        --output text)

    if [[ -n "$BLOCKED_RESOURCES" ]]; then
        echo "🔥 Eliminando recursos bloqueados..."
        for RESOURCE in $BLOCKED_RESOURCES; do
            echo "🛑 Eliminando recurso: $RESOURCE..."
            
            if [[ "$RESOURCE" == */aws/lambda/* ]]; then
                FUNCTION_NAME=$(basename "$RESOURCE")
                aws lambda delete-function --function-name "$FUNCTION_NAME" --profile $AWS_PROFILE || true
            fi
        done
    else
        echo "✅ No se encontraron recursos bloqueados en la pila."
    fi

    # 🔥 [10/11] Intentar eliminar la pila nuevamente
    echo "🔥 [10/11] Reintentando eliminación de la pila..."
    aws cloudformation delete-stack --stack-name "$STACK_NAME" --profile $AWS_PROFILE || true

    echo "⏳ [11/11] Esperando eliminación forzada de la pila..."
    aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --profile $AWS_PROFILE || {
        echo "⚠️ Algunos recursos no pudieron eliminarse. Verifique en AWS Console."
    }
}

echo "✅ ¡Todos los recursos bloqueados han sido eliminados con éxito! 🎉"
