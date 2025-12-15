#!/bin/bash

# Script de Despliegue para AhorroLand (.NET 10 + Angular 21)
# Uso: ./deploy.sh [dev|prod] [service] [options]

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }

# Variables por defecto
ENVIRONMENT=""
TARGET_SERVICE=""     # Nueva variable para el servicio específico
API_VERSION="latest"
FRONTEND_VERSION="latest"
PULL_IMAGES=false
CLEAN=false
SHOW_LOGS=false

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        dev|prod) 
            ENVIRONMENT=$1; 
            shift 
            ;;
        backend|frontend)  # Aceptamos backend o frontend como argumentos válidos
            TARGET_SERVICE=$1; 
            shift 
            ;;
        --api-version) API_VERSION="$2"; shift 2 ;;
        --frontend-version) FRONTEND_VERSION="$2"; shift 2 ;;
        --pull) PULL_IMAGES=true; shift ;;
        --clean) CLEAN=true; shift ;;
        --logs) SHOW_LOGS=true; shift ;;
        *) 
            print_error "Opción desconocida: $1"
            echo "Uso: $0 [dev|prod] [backend|frontend] [options]"
            exit 1 
            ;;
    esac
done

if [ -z "$ENVIRONMENT" ]; then
    print_error "Debes especificar un entorno (dev o prod)"
    exit 1
fi

# Configuración de archivos
if [ "$ENVIRONMENT" == "dev" ]; then
    COMPOSE_FILES="-f docker-compose.yml"
elif [ "$ENVIRONMENT" == "prod" ]; then
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.prod.yml"
    export API_VERSION
    export FRONTEND_VERSION
fi

# --- MAPEO DE SERVICIOS ---
# Esto es CRÍTICO. server.js envía "backend", pero en docker-compose el servicio puede llamarse "api"
DOCKER_SERVICE_NAME=""

if [ "$TARGET_SERVICE" == "backend" ]; then
    DOCKER_SERVICE_NAME="kash-api"  # <--- CAMBIA "api" SI TU SERVICIO EN DOCKER SE LLAMA DIFERENTE
    print_info "Modo despliegue parcial: Solo BACKEND ($DOCKER_SERVICE_NAME)"
elif [ "$TARGET_SERVICE" == "frontend" ]; then
    DOCKER_SERVICE_NAME="frontend" # <--- CAMBIA ESTO SI TU SERVICIO SE LLAMA DIFERENTE
    print_info "Modo despliegue parcial: Solo FRONTEND ($DOCKER_SERVICE_NAME)"
fi

# Validaciones de archivos
if [ ! -f "docker-compose.yml" ]; then print_error "Falta docker-compose.yml"; exit 1; fi

# Ejecución
print_info "Entorno: $ENVIRONMENT"

# 1. Limpieza (Solo si se pide explícitamente)
if [ "$CLEAN" = true ]; then
    print_info "Limpiando contenedores..."
    docker compose $COMPOSE_FILES down -v
fi

# 2. Pull (Descarga de imágenes)
if [ "$PULL_IMAGES" = true ] || [ "$ENVIRONMENT" == "prod" ]; then
    if [ -n "$DOCKER_SERVICE_NAME" ]; then
        # Solo bajamos la imagen del servicio afectado
        print_info "Descargando imagen para $DOCKER_SERVICE_NAME..."
        docker compose $COMPOSE_FILES pull "$DOCKER_SERVICE_NAME"
    else
        # Bajamos todo si no se especificó servicio
        print_info "Descargando todas las imágenes..."
        docker compose $COMPOSE_FILES pull
    fi
fi

# 3. Deploy (Levantar contenedores)
print_info "Aplicando cambios..."

if [ -n "$DOCKER_SERVICE_NAME" ]; then
    # RECREAR SOLO EL SERVICIO ESPECÍFICO (Sin tocar la BD ni el otro servicio)
    # --no-deps: No reinicia servicios vinculados (ej. base de datos)
    # --build: Fuerza recreación si cambió algo local (opcional)
    docker compose $COMPOSE_FILES up -d --no-deps "$DOCKER_SERVICE_NAME"
else
    # Comportamiento normal (Todo el stack)
    docker compose $COMPOSE_FILES up -d --remove-orphans
fi

# 4. Limpieza de imágenes viejas (Importante para no llenar el disco del VPS)
if [ "$ENVIRONMENT" == "prod" ]; then
    docker image prune -f > /dev/null 2>&1
fi

print_success "Despliegue finalizado exitosamente 🚀"

if [ "$SHOW_LOGS" = true ]; then
    docker compose $COMPOSE_FILES logs -f
fi