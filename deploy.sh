#!/bin/bash

# Script de Despliegue para AhorroLand
# Uso: ./deploy.sh [dev|prod] [version]

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de utilidad
print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Función para mostrar el uso
show_usage() {
    cat << EOF
${GREEN}AhorroLand Deployment Script${NC}

Uso: $0 [ENVIRONMENT] [OPTIONS]

Entornos:
  dev         Despliega en modo desarrollo (solo BD y phpMyAdmin)
  prod        Despliega en modo producción (completo)

Opciones:
  --api-version VERSION       Versión específica del API (por defecto: latest)
  --frontend-version VERSION  Versión específica del frontend (por defecto: latest)
  --pull                      Fuerza el pull de las imágenes
  --clean                     Limpia containers y volúmenes antes de desplegar
  --logs                      Muestra los logs después del despliegue
  -h, --help                  Muestra esta ayuda

Ejemplos:
  $0 dev                                    # Desarrollo (solo BD)
  $0 prod --api-version 1.2.3              # Producción con versión específica del API
  $0 prod --api-version 1.2.3 --frontend-version 1.2.0
  $0 dev --clean                           # Desarrollo limpiando datos antiguos
  $0 prod --clean --logs                   # Producción limpiando y mostrando logs

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
        dev|prod)
            ENVIRONMENT=$1
            shift
            ;;
        --api-version)
            API_VERSION="$2"
            shift 2
            ;;
        --frontend-version)
            FRONTEND_VERSION="$2"
            shift 2
            ;;
        --pull)
            PULL_IMAGES=true
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --logs)
            SHOW_LOGS=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Opción desconocida: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validar que se especificó un entorno
if [ -z "$ENVIRONMENT" ]; then
    print_error "Debes especificar un entorno (dev o prod)"
    show_usage
    exit 1
fi

# Configuración según el entorno
if [ "$ENVIRONMENT" == "dev" ]; then
    COMPOSE_FILES="-f docker-compose.yml"
    print_info "Desplegando en modo DESARROLLO (solo infraestructura)"
    print_warning "Backend y Frontend deben ejecutarse localmente:"
    print_warning "  Backend:  cd ../GastosApp/AhorroLand-Backend/AhorroLand/AhorroLand.NuevaApi && dotnet run"
    print_warning "  Frontend: cd ../GastosApp/GastosApp-Frontend && npm start"
elif [ "$ENVIRONMENT" == "prod" ]; then
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.prod.yml"
    print_info "Desplegando en modo PRODUCCIÓN"
    export API_VERSION
    export FRONTEND_VERSION
    print_info "API Version: $API_VERSION"
    print_info "Frontend Version: $FRONTEND_VERSION"
else
    print_error "Entorno inválido: $ENVIRONMENT"
    exit 1
fi

# Verificar que existan los archivos de docker-compose
if [ ! -f "docker-compose.yml" ]; then
    print_error "No se encontró docker-compose.yml"
    exit 1
fi

if [ "$ENVIRONMENT" == "prod" ] && [ ! -f "docker-compose.prod.yml" ]; then
    print_error "No se encontró docker-compose.prod.yml"
    exit 1
fi

# Verificar que exista el archivo .env
if [ ! -f ".env" ]; then
    print_warning "No se encontró archivo .env, usando valores por defecto"
fi

# Limpiar contenedores y volúmenes si se solicitó
if [ "$CLEAN" = true ]; then
    print_info "Limpiando contenedores y volúmenes..."
    docker-compose $COMPOSE_FILES down -v
    print_success "Limpieza completada"
fi

# Pull de imágenes si se solicitó o si es producción
if [ "$PULL_IMAGES" = true ] || [ "$ENVIRONMENT" == "prod" ]; then
    print_info "Descargando imágenes..."
    docker-compose $COMPOSE_FILES pull
    print_success "Imágenes descargadas"
fi

# Desplegar
print_info "Desplegando servicios..."
docker-compose $COMPOSE_FILES up -d

# Verificar que los servicios estén corriendo
print_info "Verificando servicios..."
sleep 5

# Obtener el estado de los servicios
SERVICES_STATUS=$(docker-compose $COMPOSE_FILES ps --services --filter "status=running")

if [ -z "$SERVICES_STATUS" ]; then
    print_error "No se pudo iniciar los servicios"
    docker-compose $COMPOSE_FILES ps
    exit 1
fi

print_success "Servicios desplegados correctamente"

# Mostrar información de los servicios
echo ""
print_info "Estado de los servicios:"
docker-compose $COMPOSE_FILES ps

# URLs de acceso
echo ""
print_success "═══════════════════════════════════════"
print_success "  AhorroLand desplegado correctamente"
print_success "═══════════════════════════════════════"
echo ""

if [ "$ENVIRONMENT" == "dev" ]; then
    print_info "🔗 Base de datos:  localhost:3307"
    print_info "🔗 phpMyAdmin:     http://localhost:8082"
    print_info ""
    print_info "Para iniciar tu aplicación:"
    print_info "  🚀 Backend:  cd ../GastosApp/AhorroLand-Backend/AhorroLand/AhorroLand.NuevaApi && dotnet run"
    print_info "  🎨 Frontend: cd ../GastosApp/GastosApp-Frontend && npm start"
elif [ "$ENVIRONMENT" == "prod" ]; then
    print_info "🔗 API:          http://localhost:5001"
    print_info "🔗 Frontend:     http://localhost:3001"
    print_info "🔗 phpMyAdmin:   http://localhost:8082"
fi

echo ""
print_info "Comandos útiles:"
print_info "  Ver logs:           docker-compose $COMPOSE_FILES logs -f"
print_info "  Detener:            docker-compose $COMPOSE_FILES stop"
print_info "  Eliminar:           docker-compose $COMPOSE_FILES down"
print_info "  Reiniciar:          docker-compose $COMPOSE_FILES restart"
print_info "  Ver estado:         docker-compose $COMPOSE_FILES ps"

# Mostrar logs si se solicitó
if [ "$SHOW_LOGS" = true ]; then
    echo ""
    print_info "Mostrando logs... (Ctrl+C para salir)"
    sleep 2
    docker-compose $COMPOSE_FILES logs -f
fi
