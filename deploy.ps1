# Deploy Script for InventorIT Kubernetes
Write-Host "Starting deployment of InventorIT..." -ForegroundColor Cyan

# 1. Check Prerequisites
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Error "kubectl is not installed or not in PATH."
    exit 1
}

# 2. Apply Namespace
Write-Host "Applying Namespace..." -ForegroundColor Yellow
kubectl apply -f manifests/namespace.yaml

# 3. Apply Configs (ConfigMaps & Secrets)
Write-Host "Applying Configuration..." -ForegroundColor Yellow
kubectl apply -f manifests/config/

# 4. Apply Database (PVC, Service, Deployment)
Write-Host "Applying Database..." -ForegroundColor Yellow
kubectl apply -f manifests/db/
Write-Host "Waiting for database to start..." -ForegroundColor Cyan
kubectl rollout status deployment/postgres -n inventorit

# 5. Apply Backend
Write-Host "Applying Backend..." -ForegroundColor Yellow
kubectl apply -f manifests/backend/
Write-Host "Waiting for backend to start..." -ForegroundColor Cyan
kubectl rollout status deployment/backend -n inventorit

# 6. Apply Frontend
Write-Host "Applying Frontend..." -ForegroundColor Yellow
kubectl apply -f manifests/frontend/

# 7. Apply NGINX Gateway
Write-Host "Applying NGINX Gateway..." -ForegroundColor Yellow
kubectl apply -f manifests/nginx/

# 8. Final Status
Write-Host "`nDeployment Complete!" -ForegroundColor Green
Write-Host "You can verify the pods with: kubectl get pods -n inventorit"
Write-Host "Access the application at: http://localhost:8080"
