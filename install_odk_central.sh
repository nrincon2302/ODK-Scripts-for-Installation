#!/usr/bin/env bash
set -euo pipefail

# =========================
# CONFIGURACIÓN INICIAL
# EDITA ESTO ANTES DE CORRER
# =========================
DOMAIN="medicionservicio.alcaldiabogota.gov.co"
SYSADMIN_EMAIL="medicionservicio@alcaldiabogota.gov.co"
PGHOST="<<SUSTITUIR POR LA IP INTERNA DE LA BASE DE DATOS POSTGRESQL>>"
PGUSER="odk"
PGPASSWORD="postgres-odk"
PGDATABASE="odk_database"
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
git clone https://SGAMB@dev.azure.com/SGAMB/HEVA%20-%20Plataforma%20Digital%20%C3%9Anica/_git/DDCS-Central central
cd central

git submodule update -i

# Configurar entorno
cp .env.template .env

# Configurar certificados SSL personalizados
cp ../certs/fullchain.pem ./files/local/customssl/fullchain.pem
cp ../certs/privkey.pem ./files/local/customssl/privkey.pem

sed -i "s|^DOMAIN=.*|DOMAIN=$DOMAIN|" .env
sed -i "s|^SYSADMIN_EMAIL=.*|SYSADMIN_EMAIL=$SYSADMIN_EMAIL|" .env
sed -i "s|^SSL_TYPE=.*|SSL_TYPE=customssl|" .env

sed -i "s|^# PGHOST=.*|PGHOST=$PGHOST|" .env
sed -i "s|^# PGUSER=.*|PGUSER=$PGUSER|" .env
sed -i "s|^# PGPASSWORD=.*|PGPASSWORD=$PGPASSWORD|" .env
sed -i "s|^# PGDATABASE=.*|PGDATABASE=$PGDATABASE|" .env

# Flag requerido para Postgres
touch ./files/allow-postgres14-upgrade

# Build y deploy
sudo docker compose build
sudo docker compose up -d

# Detener el servicio para uso de parámetros actualizados personalizados
#sudo docker compose build service && \
#sudo docker compose stop service && \
#sudo docker compose up -d service

# Estado final
sudo docker compose ps

# Crear el usuario administrador y elevar sus privilegios
echo " "
echo "👤 Registrando $SYSADMIN_EMAIL como correo administrador..."
echo "📝 Ingresa una contraseña (mínimo 8 caracteres: debe contener letras y números)"
sudo docker compose exec service odk-cmd --email $SYSADMIN_EMAIL user-create
sudo docker compose exec service odk-cmd --email $SYSADMIN_EMAIL user-promote

echo " " 
echo "✅ ODK Central instalado correctamente"
echo "👉 Accede en: https://$DOMAIN"
