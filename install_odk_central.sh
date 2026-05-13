#!/usr/bin/env bash
set -euo pipefail

# =========================
# CONFIGURACIÓN INICIAL
# EDITA ESTO ANTES DE CORRER
# =========================
DOMAIN="alcaldia-odk-prod.chickenkiller.com"
SYSADMIN_EMAIL="sampleuser@demo.com"
DB_HOST="10.128.0.8"
DB_USER="odk_usr_user"
DB_PASSWORD="postgres-odk"
DB_NAME="odk_heva"
# =========================

echo "🚀 Iniciando instalación de ODK Central"

# Dependencias necesarias
sudo apt update
sudo apt install ufw ca-certificates curl gnupg lsb-release -y

# Crear keyrings
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Agregar repositorio Docker para Ubuntu
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Actualizar e instalar Docker
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo usermod -aG sudo $USER
sudo usermod -aG docker $USER

# Verificación Docker
docker --version
docker compose version

# Deshabilitar UFW (ODK usa muchos puertos)
sudo ufw disable || true

# Clonar ODK Central
umask 022
git clone https://github.com/getodk/central
cd central

git submodule update -i

# Configurar entorno
cp .env.template .env

sed -i "s|^DOMAIN=.*|DOMAIN=$DOMAIN|" .env
sed -i "s|^SYSADMIN_EMAIL=.*|SYSADMIN_EMAIL=$SYSADMIN_EMAIL|" .env

sed -i "s|^# DB_HOST=.*|DB_HOST=$DB_HOST|" .env
sed -i "s|^# DB_USER=.*|DB_USER=$DB_USER|" .env
sed -i "s|^# DB_PASSWORD=.*|DB_PASSWORD=$DB_PASSWORD|" .env
sed -i "s|^# DB_NAME=.*|DB_NAME=$DB_NAME|" .env

# Flag requerido para Postgres
touch ./files/allow-postgres14-upgrade

# Build y deploy
sudo docker compose build
sudo docker compose up -d

# Detener el servicio para uso de base de datos personalizada externa
sudo docker compose build service && \
sudo docker compose stop service && \
sudo docker compose up -d service

# Estado final
sudo docker compose ps

# Crear el usuario administrador y elevar sus privilegios
sudo docker compose exec service odk-cmd --email $SYSADMIN_EMAIL user-create
sudo docker compose exec service odk-cmd --email $SYSADMIN_EMAIL user-promote

echo " " 
echo "✅ ODK Central instalado correctamente"
echo "👉 Accede en: https://$DOMAIN"
