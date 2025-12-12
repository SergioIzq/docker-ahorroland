#!/bin/bash

# Script de Despliegue para AhorroLand (.NET 10 + Angular 21)
# Uso: ./deploy.sh [dev|prod] [options]
# ACTUALIZADO: Usa 'docker compose' (v2) en lugar de 'docker-compose' (v1)

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorios de proyectos (informativo para dev)
BACKEND_PATH="../GastosApp/AhorroLand-Backend/AhorroLand/AhorroLand.Api"
FRONTEND_PATH="../GastosApp/GastosApp-Frontend"

print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }

show_usage() {
    cat << EOF
${GREEN}AhorroLand Deployment Script${NC}

Uso: $0 [ENVIRONMENT] [OPTIONS]

Entornos:
  dev         Despliega en modo desarrollo (solo BD y phpMyAdmin)
  prod        Despliega en modo producción (Backend .NET 10 + Frontend Angular 21)

Opciones:
  --api-version VERSION       Versión específica del API (default: latest)
  --frontend-version VERSION  Versión específica del frontend (default: latest)
  --pull                      Fuerza el pull de las imágenes
  --clean                     Limpia containers y volúmenes antes de desplegar
  --logs                      Muestra los logs después del despliegue
  -h, --help                  Muestra esta ayuda
EOF
}

# Variables por defecto
ENVIRONMENT=""
API_VERSION="latest"
FRONTEND_VERSION="latest"
PULL_IMAGES=false
CLEAN=false
SHOW_LOGS=false

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        dev|prod) ENVIRONMENT=$1; shift ;;
        --api-version) API_VERSION="$2"; shift 2 ;;
        --frontend-version) FRONTEND_VERSION="$2"; shift 2 ;;
        --pull) PULL_IMAGES=true; shift ;;
        --clean) CLEAN=true; shift ;;
        --logs) SHOW_LOGS=true; shift ;;
        -h|--help) show_usage; exit 0 ;;
        *) print_error "Opción desconocida: $1"; show_usage; exit 1 ;;
    esac
done

if [ -z "$ENVIRONMENT" ]; then
    print_error "Debes especificar un entorno (dev o prod)"
    exit 1
fi

# Configuración según el entorno
if [ "$ENVIRONMENT" == "dev" ]; then
    COMPOSE_FILES="-f docker-compose.yml"
    print_info "Desplegando infraestructura de DESARROLLO"
elif [ "$ENVIRONMENT" == "prod" ]; then
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.prod.yml"
    print_info "Desplegando PRODUCCIÓN (Full Stack Docker)"
    export API_VERSION
    export FRONTEND_VERSION
else
    print_error "Entorno inválido"
    exit 1
fi

# Validaciones de archivos
if [ ! -f "docker-compose.yml" ]; then print_error "Falta docker-compose.yml"; exit 1; fi
if [ "$ENVIRONMENT" == "prod" ] && [ ! -f "docker-compose.prod.yml" ]; then print_error "Falta docker-compose.prod.yml"; exit 1; fi
if [ ! -f ".env" ]; then print_warning "No se encontró archivo .env, usando valores por defecto"; fi

# Limpieza
if [ "$CLEAN" = true ]; then
    print_info "Limpiando contenedores..."
    # FIX: Usamos docker compose (v2)
    docker compose $COMPOSE_FILES down -v
fi

# Pull
if [ "$PULL_IMAGES" = true ] || [ "$ENVIRONMENT" == "prod" ]; then
    print_info "Descargando imágenes ($API_VERSION / $FRONTEND_VERSION)..."
    # FIX: Usamos docker compose (v2)
    docker compose $COMPOSE_FILES pull
fi

# Deploy
print_info "Iniciando servicios..."
# FIX: Usamos docker compose (v2)
docker compose $COMPOSE_FILES up -d --remove-orphans

# Verificación
print_info "Esperando arranque..."
sleep 5
# FIX: Usamos docker compose (v2)
SERVICES_STATUS=$(docker compose $COMPOSE_FILES ps --services --filter "status=running")

if [ -z "$SERVICES_STATUS" ]; then
    print_error "Fallo al iniciar servicios. Revisa los logs."
    docker compose $COMPOSE_FILES ps
    exit 1
fi

print_success "AhorroLand desplegado correctamente 🚀"
echo ""

if [ "$ENVIRONMENT" == "dev" ]; then
    print_info "🔗 BD: localhost:3307 | phpMyAdmin: localhost:8082"
elif [ "$ENVIRONMENT" == "prod" ]; then
    print_info "🔗 API: http://localhost:8080 | Frontend: http://localhost:3001"
fi

if [ "$SHOW_LOGS" = true ]; then
    # FIX: Usamos docker compose (v2)
    docker compose $COMPOSE_FILES logs -f
fi