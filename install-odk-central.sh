#!/usr/bin/env bash
set -euo pipefail

# --- Configuraciones que se deben editar ANTES de ejecutar ---
DOMAIN="https://alcaldia-odk-prod.twilightparadox.com"
SYSADMIN_EMAIL="admin@correo.com"
# -----------------------------------------------------------

echo "Iniciando instalación de ODK Central para dominio: $DOMAIN"

# 1) Actualizar e instalar dependencias
apt update -y
apt upgrade -y
apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    ufw

# 2) Instalar Docker Engine y Docker Compose
# echo "Instalando Docker..."
# mkdir -p /etc/apt/keyrings
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor \
#   -o /etc/apt/keyrings/docker.gpg

# echo \
#   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
#   https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
#   > /etc/apt/sources.list.d/docker.list

apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

docker --version
docker compose version

# 3) Opcional: Deshabilitar UFW (recomendado para el tutorial)
echo "Deshabilitando firewall UFW..."
ufw disable || true

# 4) Clonar repositorio
echo "Clonando repositorio de ODK Central..."
cd /srv
git clone https://github.com/getodk/central
cd central
git submodule update -i

# 5) Configurar variables de entorno
echo "Generando .env"
cp .env.template .env

sed -i "s|^DOMAIN=.*|DOMAIN=$DOMAIN|" .env
sed -i "s|^SYSADMIN_EMAIL=.*|SYSADMIN_EMAIL=$SYSADMIN_EMAIL|" .env

# 6) Preparar Postgres Upgrade flag
touch files/allow-postgres14-upgrade

# 7) Build (compila todo)
echo "Construyendo contenedores Docker (esto va a tardar un rato)..."
docker compose build

# 8) Levantar la aplicación
echo "Iniciando ODK Central..."
docker compose up -d

# 9) Mostrar estado
docker compose ps
