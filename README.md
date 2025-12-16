# InventorIT - Despliegue en Kubernetes

Proyecto de despliegue de la aplicacion InventorIT en Kubernetes usando kind para el Examen Final de Seguridad en Docker y Kubernetes.

## Descripcion del Proyecto

Este repositorio contiene los manifiestos de Kubernetes necesarios para desplegar la aplicacion InventorIT, un sistema de gestion de inventario de activos IT. La aplicacion esta compuesta por:

- Base de datos PostgreSQL
- Backend API REST (Node.js/Express)
- Frontend web (React)
- NGINX como reverse proxy

## Arquitectura

```
Internet
    |
    v
localhost:8080 (NodePort)
    |
    v
NGINX (Reverse Proxy)
    |
    +-- / --> Frontend Service (ClusterIP)
    |
    +-- /api --> Backend Service (ClusterIP)
                      |
                      v
                 PostgreSQL Service (ClusterIP)
```

## Componentes

### Base de Datos (PostgreSQL)
- Imagen: `alesandocker/inventorit-db:1.0.0`
- Service: ClusterIP (solo accesible dentro del cluster)
- Almacenamiento: PersistentVolumeClaim de 1Gi
- Credenciales: Gestionadas mediante Kubernetes Secret

### Backend
- Imagen: `alesandocker/inventorit-backend:1.0.0`
- Service: ClusterIP
- Variables de entorno: ConfigMap y Secret
- Health checks: Liveness y Readiness probes en `/health`
- Puerto: 3000

### Frontend
- Imagen: `alesandocker/inventorit-frontend:1.0.0`
- Service: ClusterIP
- Puerto: 80

### NGINX
- Imagen: `nginx:1.25-alpine`
- Service: NodePort (puerto 30080, mapeado a 8080 en el host)
- Configuracion: Reverse proxy mediante ConfigMap

## Requisitos Previos

- Docker Desktop instalado y corriendo
- kind instalado
- kubectl instalado

### Instalacion de kind (si no lo tienes)

En PowerShell como administrador:

```powershell
# Descargar kind
curl.exe -Lo kind-windows-amd64.exe https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64
Move-Item .\kind-windows-amd64.exe C:\Windows\System32\kind.exe
```

## Estructura del Proyecto

```
inventorit-k8s/
├── kind-config.yaml          # Configuracion del cluster kind
├── commands.txt              # Comandos paso a paso
├── README.md                 # Este archivo
└── manifests/
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
        ├── nginx-configmap.yaml       # Configuracion del reverse proxy
        ├── nginx-deployment.yaml      # Deployment de NGINX
        └── nginx-service.yaml         # Service NodePort
```

## Despliegue

### Paso 1: Crear el cluster de Kubernetes

```bash
kind create cluster --config kind-config.yaml --name inventorit
```

### Paso 2: Verificar el cluster

```bash
kubectl cluster-info --context kind-inventorit
```

### Paso 3: Desplegar la aplicacion

```bash
# Aplicar configuracion (Secrets y ConfigMaps)
kubectl apply -f manifests/config/

# Desplegar base de datos
kubectl apply -f manifests/db/

# Esperar a que la base de datos este lista
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s

# Desplegar backend
kubectl apply -f manifests/backend/

# Esperar a que el backend este listo
kubectl wait --for=condition=ready pod -l app=backend --timeout=120s

# Desplegar frontend
kubectl apply -f manifests/frontend/

# Desplegar NGINX
kubectl apply -f manifests/nginx/
```

### Paso 4: Verificar el despliegue

```bash
# Ver todos los pods
kubectl get pods

# Ver todos los servicios
kubectl get services

# Ver todos los deployments
kubectl get deployments
```

Deberias ver algo similar a:

```
NAME                        READY   STATUS    RESTARTS   AGE
backend-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
frontend-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
nginx-xxxxxxxxxx-xxxxx      1/1     Running   0          1m
postgres-xxxxxxxxxx-xxxxx   1/1     Running   0          3m
```

### Paso 5: Acceder a la aplicacion

Abre tu navegador y ve a:

```
http://localhost:8080
```

## Verificacion de Logs

Si encuentras problemas, puedes revisar los logs de cada componente:

```bash
# Logs del backend
kubectl logs -l app=backend

# Logs de la base de datos
kubectl logs -l app=postgres

# Logs del frontend
kubectl logs -l app=frontend

# Logs de NGINX
kubectl logs -l app=nginx
```

## Buenas Practicas de Seguridad Implementadas

1. **No usar contenedores privilegiados**: Todos los deployments tienen `allowPrivilegeEscalation: false`
2. **No usar tags latest**: Todas las imagenes usan versiones especificas
3. **Separacion de Secrets y ConfigMaps**: Las credenciales estan en Secrets, la configuracion en ConfigMaps
4. **RunAsNonRoot**: Los contenedores corren con usuarios no privilegiados
5. **Resource Limits**: Todos los contenedores tienen limites de CPU y memoria
6. **ClusterIP para servicios internos**: Solo NGINX esta expuesto via NodePort
7. **Health Checks**: El backend tiene liveness y readiness probes
8. **Almacenamiento persistente**: La base de datos usa PVC para persistencia

## Limpieza

Para eliminar todo el despliegue:

```bash
# Eliminar todos los recursos
kubectl delete -f manifests/nginx/
kubectl delete -f manifests/frontend/
kubectl delete -f manifests/backend/
kubectl delete -f manifests/db/
kubectl delete -f manifests/config/

# Eliminar el cluster completo
kind delete cluster --name inventorit
```

## Credenciales por Defecto

Las credenciales de la base de datos estan definidas en `manifests/config/postgres-secret.yaml`:

- Usuario: `inventorit_user`
- Contrasena: `inventorit_pass_2024`
- Base de datos: `inventorit_db`

**Nota**: En un entorno de produccion, estas credenciales deberian estar encriptadas y gestionadas de forma segura.

## Troubleshooting

### Los pods no inician

```bash
kubectl describe pod <nombre-del-pod>
```

### El backend no se conecta a la base de datos

Verifica que el servicio de PostgreSQL este corriendo:

```bash
kubectl get service postgres-service
```

### No puedo acceder a la aplicacion en localhost:8080

Verifica que el servicio NGINX este corriendo y el NodePort este configurado:

```bash
kubectl get service nginx-service
```

## Notas para Evaluacion

- Este proyecto usa exclusivamente Kubernetes para el despliegue
- No se construyen imagenes nuevas, solo se usan las existentes en Docker Hub
- Todos los manifiestos son declarativos
- Se aplican buenas practicas de seguridad vistas en el curso
- El proyecto es reproducible en Windows 11 con Docker Desktop y kind

## Autor

Proyecto desarrollado para el Examen Final de Seguridad en Docker y Kubernetes.
