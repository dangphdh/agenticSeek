# AgenticSeek Helm Chart Installation Guide

This guide provides instructions for deploying AgenticSeek using Helm charts on Kubernetes clusters.

## Prerequisites

Before installing the AgenticSeek Helm chart, ensure you have:

### 1. Kubernetes Cluster
- A running Kubernetes cluster (v1.20+)
- `kubectl` configured to access your cluster
- Sufficient resources (minimum 4 CPU cores, 8GB RAM)

### 2. Helm
- Helm v3.8+ installed
- Access to your Kubernetes cluster with appropriate RBAC permissions

### 3. Required Dependencies
- **Ingress Controller** (e.g., NGINX Ingress Controller)
- **Cert-Manager** (optional, for TLS certificates)
- **Storage Class** for persistent volumes
- **Container Images** (build or pull from registry)

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/your-org/agenticseek.git
cd agenticseek/helm
```

### 2. Install Dependencies

#### Install NGINX Ingress Controller
```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

#### Install Cert-Manager (Optional)
```bash
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0 \
  --set installCRDs=true
```

### 3. Prepare Configuration

#### Create a Custom Values File
```bash
cp agenticseek/values.yaml my-values.yaml
```

#### Configure Required Settings
Edit `my-values.yaml` and set the following:

```yaml
# Container images - Build or specify your registry
backend:
  image:
    repository: your-registry/agenticseek-backend
    tag: "v1.0.0"

frontend:
  image:
    repository: your-registry/agenticseek-frontend
    tag: "v1.0.0"

# Ingress configuration
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: agenticseek.yourdomain.com
      paths:
        - path: /api
          pathType: Prefix
          backend: backend
        - path: /
          pathType: Prefix
          backend: frontend
  tls:
    - secretName: agenticseek-tls
      hosts:
        - agenticseek.yourdomain.com

# API Keys (base64 encoded)
secrets:
  openaiApiKey: "base64-encoded-key"
  deepseekApiKey: "base64-encoded-key"
  searxngSecretKey: "base64-encoded-secret"
  # Add other API keys as needed
```

### 4. Install the Chart
```bash
helm install agenticseek ./agenticseek -f my-values.yaml
```

## Advanced Configuration

### Environment-Specific Deployments

#### Development Environment
```yaml
# dev-values.yaml
backend:
  replicaCount: 1
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 1000m
      memory: 2Gi

frontend:
  replicaCount: 1

autoscaling:
  enabled: false

ingress:
  hosts:
    - host: agenticseek-dev.local
```

#### Production Environment
```yaml
# prod-values.yaml
backend:
  replicaCount: 3
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi

frontend:
  replicaCount: 2

autoscaling:
  enabled: true
  backend:
    minReplicas: 3
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70

persistence:
  enabled: true
  size: 50Gi
  storageClass: "fast-ssd"

redis:
  auth:
    enabled: true
  persistence:
    enabled: true
    size: 5Gi
```

### SSL/TLS Configuration

#### Using Cert-Manager with Let's Encrypt
```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: agenticseek.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
          backend: frontend
        - path: /api
          pathType: Prefix
          backend: backend
  tls:
    - secretName: agenticseek-tls
      hosts:
        - agenticseek.yourdomain.com
```

#### Using Custom TLS Certificates
```bash
# Create TLS secret manually
kubectl create secret tls agenticseek-tls \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key
```

### Monitoring and Observability

#### Enable Prometheus Metrics
```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
    path: /metrics
```

#### Resource Monitoring
```yaml
backend:
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi

frontend:
  resources:
    requests:
      cpu: 250m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
```

## Configuration Options

### Core Components

#### Backend Configuration
```yaml
backend:
  replicaCount: 2
  image:
    repository: agenticseek-backend
    tag: "latest"
    pullPolicy: IfNotPresent
  
  env:
    SEARXNG_URL: "http://agenticseek-searxng:8080"
    REDIS_URL: "redis://agenticseek-redis:6379/0"
    DEPLOYMENT_MODE: "cloud"
    LOG_LEVEL: "INFO"
  
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
```

#### Frontend Configuration
```yaml
frontend:
  replicaCount: 2
  image:
    repository: agenticseek-frontend
    tag: "latest"
    pullPolicy: IfNotPresent
  
  env:
    REACT_APP_BACKEND_URL: "http://agenticseek-backend:7777"
```

#### SearXNG Configuration
```yaml
searxng:
  replicaCount: 1
  image:
    repository: searxng/searxng
    tag: "latest"
  
  baseUrl: "http://localhost:8080"
  
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 1Gi
```

#### Redis Configuration
```yaml
redis:
  replicaCount: 1
  image:
    repository: redis
    tag: "7-alpine"
  
  auth:
    enabled: false  # Set to true for production
  
  persistence:
    enabled: true
    size: 1Gi
    storageClass: ""
```

## Operations

### Installation Commands

#### Install with Default Values
```bash
helm install agenticseek ./agenticseek
```

#### Install with Custom Values
```bash
helm install agenticseek ./agenticseek -f my-values.yaml
```

#### Install in Specific Namespace
```bash
helm install agenticseek ./agenticseek \
  --namespace agenticseek \
  --create-namespace \
  -f my-values.yaml
```

### Upgrade Commands

#### Upgrade with New Values
```bash
helm upgrade agenticseek ./agenticseek -f my-values.yaml
```

#### Upgrade with New Image Tag
```bash
helm upgrade agenticseek ./agenticseek \
  --set backend.image.tag=v1.1.0 \
  --set frontend.image.tag=v1.1.0
```

### Management Commands

#### Check Release Status
```bash
helm status agenticseek
```

#### View Current Values
```bash
helm get values agenticseek
```

#### Rollback to Previous Version
```bash
helm rollback agenticseek 1
```

#### Uninstall Release
```bash
helm uninstall agenticseek
```

## Troubleshooting

### Common Issues

#### 1. Image Pull Errors
```bash
# Check if images exist and are accessible
kubectl describe pod <pod-name>

# Verify image pull secrets
kubectl get secrets
```

#### 2. Persistent Volume Issues
```bash
# Check PVC status
kubectl get pvc

# Check available storage classes
kubectl get storageclass
```

#### 3. Ingress Not Working
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Verify ingress configuration
kubectl describe ingress agenticseek-ingress
```

#### 4. Service Connection Issues
```bash
# Check service endpoints
kubectl get svc
kubectl get endpoints

# Test internal connectivity
kubectl exec -it <pod-name> -- curl http://service-name:port
```

### Debug Commands

#### Check Pod Logs
```bash
# Backend logs
kubectl logs -l app.kubernetes.io/component=backend

# Frontend logs
kubectl logs -l app.kubernetes.io/component=frontend

# SearXNG logs
kubectl logs -l app.kubernetes.io/component=searxng

# Follow logs in real-time
kubectl logs -f deployment/agenticseek-backend
```

#### Check Resource Usage
```bash
# Pod resource usage
kubectl top pods

# Node resource usage
kubectl top nodes
```

#### Port Forward for Testing
```bash
# Access backend directly
kubectl port-forward svc/agenticseek-backend 7777:7777

# Access frontend directly
kubectl port-forward svc/agenticseek-frontend 3000:80
```

## Security Considerations

### 1. API Key Management
- Store API keys as Kubernetes secrets
- Use base64 encoding for secret values
- Consider using external secret management (e.g., HashiCorp Vault)

### 2. Network Security
- Enable network policies if required
- Use TLS for all external communications
- Restrict ingress to specific IP ranges if needed

### 3. Pod Security
- Run containers as non-root users
- Use read-only root filesystems where possible
- Drop unnecessary capabilities

### 4. RBAC
- Create dedicated service accounts
- Apply principle of least privilege
- Regular audit of permissions

## Performance Tuning

### Resource Optimization
```yaml
backend:
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi

frontend:
  resources:
    requests:
      cpu: 250m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
```

### Horizontal Pod Autoscaling
```yaml
autoscaling:
  enabled: true
  backend:
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80
```

### Storage Performance
```yaml
persistence:
  enabled: true
  storageClass: "ssd-fast"  # Use SSD storage classes
  size: 50Gi

redis:
  persistence:
    enabled: true
    storageClass: "ssd-fast"
    size: 5Gi
```

## Support

For issues and questions:
- Check the troubleshooting section above
- Review Kubernetes and Helm documentation
- Open an issue in the project repository
- Consult your Kubernetes cluster administrator

## Chart Values Reference

For a complete reference of all available configuration options, see the `values.yaml` file in the chart directory or run:

```bash
helm show values ./agenticseek
```
