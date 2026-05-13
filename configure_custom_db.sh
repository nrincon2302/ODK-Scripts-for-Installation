#!/usr/bin/env bash
set -euo pipefail

# =========================
# CONFIGURACIÓN INICIAL
# EDITA ESTO ANTES DE CORRER
# =========================
DB_USER="odk"
DB_PASSWORD="postgres-odk"
DB_NAME="odk_database_chickenkiller"
# =========================

echo "🚀 Iniciando configuración de base de datos Postgres 16"

# Configuraciones y dependencias
sudo apt update
sudo apt install -y wget ca-certificates gnupg lsb-release
wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc |   sudo gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] \
http://apt.postgresql.org/pub/repos/apt \
$(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list

# Instalar Postgres 16
sudo apt update
sudo apt install -y postgresql-16 postgresql-client-16

# Editar los archivos de Postgres para escuchar todos los hosts
sudo sed -i "s|^[#[:space:]]*listen_addresses[[:space:]]*=.*|listen_addresses = '*'|" \
  /etc/postgresql/16/main/postgresql.conf

PG_HBA="/etc/postgresql/16/main/pg_hba.conf"
LINE="host    all    all    10.128.0.0/16    md5"

sudo grep -qxF "$LINE" "$PG_HBA" || echo "$LINE" | sudo tee -a "$PG_HBA" > /dev/null

# Reiniciar el servicio
sudo systemctl restart postgresql

# Comprobar que se aplicaron los cambios
sudo ss -lntp | grep 5432

# Acceder a la base de datos para crear la base y el usuario
sudo -u postgres psql <<EOF
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8';

\c $DB_NAME

CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgrowlocks;
EOF

echo " " 
echo "✅ Base de datos creada y configurada correctamente"