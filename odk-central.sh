#!/usr/bin/env bash
set -euo pipefail

# =========================
# CONFIGURACIÓN INICIAL
# EDITA ESTO ANTES DE CORRER
# =========================
DOMAIN="https://alcaldia-odk-prod.twilightparadox.com"
SYSADMIN_EMAIL="admin@email.com"
INSTALL_DIR="/srv"
# =========================

echo "🚀 Iniciando instalación de ODK Central"
echo "🌐 DOMAIN=$DOMAIN"
echo "📧 SYSADMIN_EMAIL=$SYSADMIN_EMAIL"

# 1️⃣ Actualizar sistema
sudo apt update -y
sudo apt upgrade -y

# 2️⃣ Dependencias base
sudo apt install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  software-properties-common \
  git

# 3️⃣ Instalar Docker (forma correcta)
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y

sudo apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-compose-plugin

# 4️⃣ Verificación Docker
docker --version
docker compose version

# 5️⃣ Deshabilitar UFW (ODK usa muchos puertos)
sudo ufw disable || true

# 6️⃣ Clonar ODK Central
cd "$INSTALL_DIR"
sudo git clone https://github.com/getodk/central
sudo chown -R "$USER:$USER" central
cd central

git submodule update -i

# 7️⃣ Configurar entorno
cp .env.template .env

sed -i "s|^DOMAIN=.*|DOMAIN=$DOMAIN|" .env
sed -i "s|^SYSADMIN_EMAIL=.*|SYSADMIN_EMAIL=$SYSADMIN_EMAIL|" .env

# 8️⃣ Flag requerido para Postgres
touch files/allow-postgres14-upgrade

# 9️⃣ Build y deploy
docker compose build
docker compose up -d

# 🔟 Estado final
docker compose ps

echo "✅ ODK Central instalado correctamente"
echo "👉 Accede en: https://$DOMAIN"
