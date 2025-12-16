# Examen Final de Security Docker & Kubernetes - Hackademy

Despliegue de la aplicación InventorIT usando Kubernetes con kind.

## Descripción

Este repositorio contiene los manifiestos necesarios para desplegar InventorIT (sistema de gestión de inventario IT) en Kubernetes. La aplicación tiene:

- Base de datos PostgreSQL para almacenar los datos
- Backend API REST en Node.js/Express
- Frontend en React
- NGINX como reverse proxy

Todo se despliega en el namespace `inventorit`.

## Arquitectura

```
localhost:8080 (NodePort)
    |
    v
NGINX (Reverse Proxy)
    |
    +-- / --> Frontend (ClusterIP)
    |
    +-- /api --> Backend (ClusterIP)
                      |
                      v
                 PostgreSQL (ClusterIP)
```

## Requisitos

Necesitas tener instalado:

1. Docker Desktop (corriendo)
2. kubectl
3. kind

Para verificar que los tienes:

```bash
docker --version
kubectl version --client
kind --version
```

Si no tienes kind, instalalo así (PowerShell como admin):

```powershell
curl.exe -Lo kind-windows-amd64.exe https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64
Move-Item .\kind-windows-amd64.exe C:\Windows\System32\kind.exe
```

## Estructura del Proyecto

```
inventorit-k8s/
├── kind-config.yaml              # Configuración del cluster kind
├── commands.txt                  # Comandos de despliegue paso a paso
├── README.md                     # Este archivo
└── manifests/
    ├── namespace.yaml            # Namespace dedicado
    ├── config/
    │   ├── postgres-secret.yaml       # Credenciales de PostgreSQL
    │   └── backend-configmap.yaml     # Variables de entorno del backend
    ├── db/
    │   ├── postgres-pvc.yaml          # Almacenamiento persistente
    │   ├── postgres-deployment.yaml   # Deployment de PostgreSQL
    │   └── postgres-service.yaml      # Service ClusterIP
    ├── backend/
    │   ├── backend-deployment.yaml    # Deployment del backend
    │   └── backend-service.yaml       # Service ClusterIP
    ├── frontend/
    │   ├── frontend-deployment.yaml   # Deployment del frontend
    │   └── frontend-service.yaml      # Service ClusterIP
    └── nginx/
        ├── nginx-configmap.yaml       # Configuración del reverse proxy
        ├── nginx-deployment.yaml      # Deployment de NGINX
        └── nginx-service.yaml         # Service NodePort
```

## Cómo Desplegar

### 1. Crear el cluster

```bash
kind create cluster --config kind-config.yaml --name inventorit
```

### 2. Crear el namespace

```bash
kubectl apply -f manifests/namespace.yaml
```

### 3. Desplegar todo

```bash
# Configuración
kubectl apply -f manifests/config/

# Base de datos
kubectl apply -f manifests/db/
kubectl rollout status deployment/postgres -n inventorit

# Backend
kubectl apply -f manifests/backend/
kubectl rollout status deployment/backend -n inventorit

# Frontend
kubectl apply -f manifests/frontend/

# NGINX
kubectl apply -f manifests/nginx/
```

### 4. Verificar

```bash
kubectl get pods -n inventorit
kubectl get svc -n inventorit
```

Deberías ver 4 pods corriendo (postgres, backend, frontend, nginx).

### 5. Acceder

Abre el navegador en: `http://localhost:8080`

## Seguridad Implementada

He aplicado las siguientes prácticas de seguridad vistas en el curso:

### Namespace Dedicado
- Todo en el namespace `inventorit` para mejor organización
- Facilita limpieza y aislamiento

### Security Contexts
Todos los contenedores tienen:
- `allowPrivilegeEscalation: false`
- `runAsNonRoot: true`
- `readOnlyRootFilesystem: true`
- `capabilities: drop: ["ALL"]`

PostgreSQL usa `fsGroup: 999` para permisos correctos del volumen.

### Health Probes
- Backend: probes en `/health`
- Frontend y NGINX: probes HTTP
- PostgreSQL: usa `pg_isready`

### Gestión de Credenciales
- Secrets para credenciales de DB
- ConfigMaps para variables no sensibles
- Sin credenciales hardcodeadas

### Red
- Solo NGINX expuesto (NodePort)
- Backend, frontend y DB son ClusterIP (internos)
- PostgreSQL no accesible desde fuera

### Recursos
- Todos los pods tienen limits y requests
- Previene consumo excesivo

### Imágenes
- Sin tag `latest`
- Versiones específicas en todas las imágenes

## Troubleshooting

### Ver logs

```bash
kubectl logs -l app=backend -n inventorit
kubectl logs -l app=postgres -n inventorit
kubectl logs -l app=frontend -n inventorit
kubectl logs -l app=nginx -n inventorit
```

### Si los pods no inician

```bash
kubectl get events -n inventorit --sort-by='.lastTimestamp'
kubectl describe pod <nombre-del-pod> -n inventorit
```

### Si el backend no conecta a la DB

```bash
kubectl get pod -l app=postgres -n inventorit
kubectl logs -l app=postgres -n inventorit
```

### Si no funciona localhost:8080

```bash
kubectl get svc nginx-service -n inventorit
```

Debe mostrar NodePort 30080.

### Errores de permisos en PostgreSQL

```bash
kubectl logs -l app=postgres -n inventorit
```

Busca errores en `/var/lib/postgresql/data`.

## Limpieza

Para eliminar todo:

```bash
# Opción 1: Borrar solo el namespace
kubectl delete namespace inventorit

# Opción 2: Borrar el cluster completo
kind delete cluster --name inventorit
```

## Credenciales

Las credenciales están en `manifests/config/postgres-secret.yaml`:

**Base de datos:**
- Usuario: `postgres`
- Contraseña: `inventorit_pass_2024`
- Base de datos: `inventorit_db`

**Usuario admin por defecto:**
- Usuario: `admin`
- Contraseña: `Adm1n_Secur3!2025`

> ⚠️ Cambiar la contraseña del admin después del primer login en producción.

## Componentes

### Base de Datos
- Imagen: `alesandocker/inventorit-db:1.0.0`
- Almacenamiento: 1Gi PVC
- Puerto: 5432 (interno)
- Usuario: postgres

### Backend
- Imagen: `alesandocker/inventorit-backend:1.0.0`
- Puerto: 3000 (interno)
- Health: `/health`
- WebSocket: Socket.IO en `/socket.io/`

### Frontend
- Imagen: `alesandocker/inventorit-frontend:1.0.0`
- Puerto: 8080 (interno)
- React SPA

### NGINX
- Imagen: `nginx:1.28.0-alpine`
- Puerto: 80 → NodePort 30080 → Host 8080
- Rutas: 
  - `/` → frontend (8080)
  - `/api/` → backend (3000)
  - `/socket.io/` → backend WebSocket
  - `/uploads/` → backend uploads

## Notas
- Proyecto 100% Kubernetes
- Usa imágenes de Docker Hub
- Manifiestos organizados por componente
- Namespace dedicado
- Seguridad aplicada según lo visto en clase
- Health probes en todos los componentes
