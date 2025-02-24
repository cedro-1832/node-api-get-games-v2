#!/bin/bash

echo "🚀 Iniciando API de PlayStation Games..."

# Verificar si Node.js está instalado
if ! command -v node &> /dev/null; then
    echo "❌ Node.js no está instalado. Instalándolo..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    sudo apt-get install -y nodejs
    exit 1
fi

# Verificar la versión de Node.js y cambiarla si es necesario
NODE_VERSION=$(node -v | cut -d 'v' -f 2 | cut -d '.' -f 1)
if [ "$NODE_VERSION" -ge 21 ]; then
    echo "⚠️  Advertencia: Estás usando Node.js v$NODE_VERSION. Se recomienda usar Node.js 18 o 20."
    
    if command -v nvm &> /dev/null; then
        echo "🔄 Cambiando a Node.js 20 con NVM..."
        nvm install 20
        nvm use 20
    else
        echo "⚠️  Instalando NVM y cambiando a Node.js 20..."
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        nvm install 20
        nvm use 20
    fi
fi

# Verificar si package.json existe y corregir si está corrupto o vacío
if [ ! -f "package.json" ] || [ ! -s "package.json" ]; then
    echo "❌ package.json está corrupto o vacío. Regenerándolo..."
    rm -f package.json package-lock.json
    npm init -y
fi

# Verificar si node_modules existe, si no, reinstalar dependencias
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependencias..."
    npm install
else
    echo "✅ Dependencias ya instaladas."
fi

# Limpiar caché de npm si hay errores previos
npm cache clean --force

# Verificar si el puerto 3000 está en uso y matar el proceso si es necesario
PORT=3000
if lsof -i:$PORT -t >/dev/null 2>&1; then
    echo "⚠️  El puerto $PORT está en uso. Matando el proceso..."
    kill -9 $(lsof -t -i:$PORT)
    sleep 2
fi

# Cargar variables de entorno desde .env
if [ -f ".env" ]; then
    echo "✅ Cargando credenciales desde .env..."
    export $(grep -v '^#' .env | xargs)
else
    echo "❌ No se encontró el archivo .env. Creando uno nuevo..."

    cat <<EOL > .env
AWS_ACCESS_KEY_ID=TU_AWS_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=TU_AWS_SECRET_KEY
AWS_REGION=us-east-1
JWT_SECRET=supersecreto
PORT=3000
EOL

    echo "⚠️  Se ha creado el archivo .env. 📌 **MODIFÍCALO MANUALMENTE** con tus credenciales antes de continuar."
    exit 1
fi

# Ejecutar la API en modo desarrollo con nodemon si está instalado
if command -v nodemon &> /dev/null; then
    echo "🔄 Ejecutando API con Nodemon..."
    nodemon server.js
else
    echo "⚡ Ejecutando API con Node.js..."
    node server.js
fi
