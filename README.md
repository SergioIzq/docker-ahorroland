# 🐳 Docker AhorroLand

<div align="center">

![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)
![Backend Status](https://img.shields.io/docker/v/sergioizqdev/ahorroland-backend?label=backend&logo=docker)
![Frontend Status](https://img.shields.io/docker/v/sergioizqdev/ahorroland-frontend?label=frontend&logo=docker)
![License](https://img.shields.io/github/license/SergioIzq/docker-ahorroland)

</div>

---

Este repositorio contiene todos los archivos de Docker necesarios para desplegar el proyecto AhorroLand (Backend + Frontend + Base de Datos).

## 📋 Tabla de Contenidos

- [Estructura del Proyecto](#estructura-del-proyecto)
- [Requisitos Previos](#requisitos-previos)
- [Inicio Rápido](#inicio-rápido)
- [Entornos](#entornos)
- [Configuración](#configuración)
- [Uso](#uso)
- [CI/CD](#cicd)
- [Troubleshooting](#troubleshooting)

## 🏗️ Estructura del Proyecto

```
docker-ahorroland/
├── docker-compose.yml          # Configuración base (DB, phpMyAdmin)
├── docker-compose.dev.yml      # Configuración de desarrollo
├── docker-compose.prod.yml     # Configuración de producción
├── .env.example                # Ejemplo de variables de entorno
├── deploy.sh                   # Script de despliegue automatizado
├── SETUP_CICD_GUIDE.md        # Guía completa de CI/CD
├── README.md                   # Este archivo
└── LICENSE
```

## 🔧 Requisitos Previos

- [Docker](https://www.docker.com/get-started) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)
- Para desarrollo:
  - [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
  - [Node.js 20+](https://nodejs.org/)

## 🚀 Inicio Rápido

### 1. Clona el repositorio

```bash
git clone https://github.com/SergioIzq/docker-ahorroland.git
cd docker-ahorroland
```

### 2. Configura las variables de entorno

```bash
cp .env.example .env
# Edita .env con tus configuraciones
```

### 3. Despliega en producción

```bash
# Usando el script de despliegue
./deploy.sh prod

# O manualmente
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### 4. Accede a la aplicación

- **Frontend**: http://localhost:8080
- **API**: http://localhost
- **phpMyAdmin**: http://localhost:8081

## 🌍 Entornos

### Desarrollo (`dev`)

- Hot-reload habilitado para backend y frontend
- Código fuente montado como volúmenes
- Ideal para desarrollo local

```bash
./deploy.sh dev
```

**URLs de desarrollo:**
- Frontend: http://localhost:4200
- API: http://localhost:5001
- phpMyAdmin: http://localhost:8081

### Producción (`prod`)

- Usa imágenes pre-construidas desde Docker Hub
- Optimizado para rendimiento
- Sin hot-reload

```bash
./deploy.sh prod
```

**URLs de producción:**
- Frontend: http://localhost:8080
- API: http://localhost
- phpMyAdmin: http://localhost:8081

## ⚙️ Configuración

### Variables de Entorno

Crea un archivo `.env` basado en `.env.example`:

```bash
# Versiones de las imágenes
API_VERSION=latest
FRONTEND_VERSION=latest

# Base de datos
MYSQL_DATABASE=ahorroland
MYSQL_ROOT_PASSWORD=tu_password_seguro
```

### Usando Versiones Específicas

Para desplegar versiones específicas de las aplicaciones:

```bash
# Opción 1: Modificar .env
API_VERSION=1.2.3
FRONTEND_VERSION=1.2.3

# Opción 2: Variables de entorno en línea
API_VERSION=1.2.3 FRONTEND_VERSION=1.2.3 ./deploy.sh prod

# Opción 3: Argumentos del script
./deploy.sh prod --api-version 1.2.3 --frontend-version 1.2.3
```

## 📖 Uso

### Script de Despliegue (Recomendado)

```bash
# Desarrollo
./deploy.sh dev

# Producción
./deploy.sh prod

# Producción con versiones específicas
./deploy.sh prod --api-version 1.2.3 --frontend-version 1.2.0

# Ver todas las opciones
./deploy.sh --help
```

### Comandos Docker Compose

#### Desarrollo

```bash
# Iniciar servicios
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Ver logs
docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f

# Detener servicios
docker-compose -f docker-compose.yml -f docker-compose.dev.yml down

# Reconstruir imágenes
docker-compose -f docker-compose.yml -f docker-compose.dev.yml build --no-cache
```

#### Producción

```bash
# Descargar las últimas imágenes
docker-compose -f docker-compose.yml -f docker-compose.prod.yml pull

# Iniciar servicios
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Ver logs
docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f

# Detener servicios
docker-compose -f docker-compose.yml -f docker-compose.prod.yml down

# Detener y eliminar volúmenes (⚠️ borra la base de datos)
docker-compose -f docker-compose.yml -f docker-compose.prod.yml down -v
```

### Comandos Útiles

```bash
# Ver estado de los servicios
docker-compose ps

# Reiniciar un servicio específico
docker-compose restart api
docker-compose restart frontend

# Ver logs de un servicio específico
docker-compose logs -f api
docker-compose logs -f frontend
docker-compose logs -f db

# Ejecutar comandos dentro de un contenedor
docker-compose exec api bash
docker-compose exec frontend sh

# Ver uso de recursos
docker stats

# Limpiar recursos de Docker
docker system prune -a
```

## 🔄 CI/CD

Este proyecto incluye pipelines de CI/CD con GitHub Actions que automáticamente construyen y publican imágenes Docker.

### Configuración CI/CD

Para configurar los pipelines de CI/CD, consulta la guía completa:

📖 **[SETUP_CICD_GUIDE.md](SETUP_CICD_GUIDE.md)**

### Imágenes Docker

Las imágenes se publican automáticamente en Docker Hub:

- **Backend**: [sergioizqdev/ahorroland-backend](https://hub.docker.com/r/sergioizqdev/ahorroland-backend)
- **Frontend**: [sergioizqdev/ahorroland-frontend](https://hub.docker.com/r/sergioizqdev/ahorroland-frontend)

### Flujo de Trabajo

1. Push a `develop` → Construye imagen con tag `develop`
2. Push a `main` → Construye imagen con tag `latest`
3. Tag `v1.2.3` → Construye imágenes con tags `1.2.3`, `1.2`, `1`, `latest`

## 🐛 Troubleshooting

### Los contenedores no inician

```bash
# Verifica el estado
docker-compose ps

# Ver logs para identificar el problema
docker-compose logs

# Reinicia los servicios
docker-compose restart
```

### Error de conexión a la base de datos

1. Verifica que el contenedor de la BD esté corriendo:
   ```bash
   docker-compose ps db
   ```

2. Verifica las credenciales en `.env`

3. Espera unos segundos más (la BD puede tardar en iniciar)

### El frontend no se conecta al backend

1. Verifica que ambos contenedores estén en la misma red:
   ```bash
   docker network inspect docker-ahorroland_ahorroland-red
   ```

2. Verifica la configuración de CORS en el backend

3. Revisa las variables de entorno del frontend

### Las imágenes no se actualizan

```bash
# Limpia la caché de Docker
docker system prune -a

# Fuerza el pull de las nuevas imágenes
docker-compose pull

# Recrea los contenedores
docker-compose up -d --force-recreate
```

### Problemas de permisos en desarrollo

```bash
# En Linux/Mac, puede que necesites ajustar permisos
sudo chown -R $USER:$USER ../GastosApp
```

### Puerto ya en uso

```bash
# Encuentra qué está usando el puerto
lsof -i :80     # Linux/Mac
netstat -ano | findstr :80  # Windows

# Cambia el puerto en docker-compose.yml o detén el servicio que lo usa
```

## 📊 Monitoreo

### Salud de los Servicios

```bash
# Ver estado de todos los servicios
docker-compose ps

# Ver uso de recursos en tiempo real
docker stats

# Ver logs en tiempo real
docker-compose logs -f
```

### Base de Datos

Accede a phpMyAdmin en http://localhost:8081

- **Servidor**: `db`
- **Usuario**: `root`
- **Contraseña**: (la que configuraste en `.env`)

## 🔒 Seguridad

- ⚠️ **NUNCA** comitees el archivo `.env` con contraseñas reales
- 🔑 Usa contraseñas seguras en producción
- 🔄 Rota las credenciales periódicamente
- 🚫 Restringe el acceso a phpMyAdmin en producción
- 🔐 Considera usar HTTPS en producción (con Nginx/Traefik)

## 📚 Recursos Adicionales

- [Guía de CI/CD](SETUP_CICD_GUIDE.md)
- [Documentación de Docker](https://docs.docker.com/)
- [Documentación de Docker Compose](https://docs.docker.com/compose/)

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la licencia especificada en el archivo LICENSE.

## 👤 Autor

**Sergio Izquierdo**

- GitHub: [@SergioIzq](https://github.com/SergioIzq)
- Docker Hub: [@sergioizqdev](https://hub.docker.com/u/sergioizqdev)

---

⭐ Si este proyecto te fue útil, considera darle una estrella en GitHub!
