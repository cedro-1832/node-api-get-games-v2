#!/bin/bash

# Detener ejecución en caso de error
set -e

# Configurar el perfil de AWS correcto
export AWS_PROFILE="serverless-deployer"

# Verificar que el perfil se ha configurado correctamente
echo "✅ AWS_PROFILE configurado como: $AWS_PROFILE"

# Agregarlo a la sesión actual (opcional, útil si usas zsh o bash)
echo "export AWS_PROFILE='serverless-deployer'" >> ~/.bash_profile  # Para bash
echo "export AWS_PROFILE='serverless-deployer'" >> ~/.zshrc          # Para zsh
source ~/.bash_profile 2>/dev/null || source ~/.zshrc 2>/dev/null

# Validar la configuración con AWS CLI
aws sts get-caller-identity --profile "$AWS_PROFILE"

# Mensaje de éxito
echo "✅ AWS_PROFILE '$AWS_PROFILE' está correctamente configurado."

