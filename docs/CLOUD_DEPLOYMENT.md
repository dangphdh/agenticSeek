# AgenticSeek Cloud Deployment Guide

This comprehensive guide covers deploying AgenticSeek in cloud environments, including major cloud providers, Kubernetes clusters, Docker deployments, and the new Helm charts for streamlined Kubernetes deployments.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Helm Chart Deployment (Recommended)](#helm-chart-deployment-recommended)
4. [Cloud Provider Deployment](#cloud-provider-deployment)
5. [Kubernetes Deployment](#kubernetes-deployment)
6. [Docker Cloud Deployment](#docker-cloud-deployment)
7. [Environment Configuration](#environment-configuration)
8. [Security Considerations](#security-considerations)
9. [Monitoring & Logging](#monitoring--logging)
10. [Scaling & Performance](#scaling--performance)
11. [CI/CD Pipeline](#cicd-pipeline)
12. [Troubleshooting](#troubleshooting)

## Overview

AgenticSeek can be deployed in cloud environments while maintaining its core functionality as a private AI assistant. Cloud deployment offers scalability, reliability, and managed infrastructure benefits while keeping your data secure within your cloud environment.

### Cloud Deployment Benefits

- **Scalability**: Automatically scale based on demand
- **Reliability**: High availability with cloud provider SLAs
- **Managed Services**: Leverage managed databases, storage, and networking
- **Global Reach**: Deploy in multiple regions for better performance
- **Cost Optimization**: Pay-as-you-use pricing models
- **Easy Management**: Helm charts for streamlined Kubernetes deployments

### Important Considerations

⚠️ **Privacy Notice**: While AgenticSeek maintains data privacy within your cloud environment, ensure you configure proper network security and access controls to maintain the privacy guarantees.

## Architecture

### Cloud Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Load Balancer / Ingress                  │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────┴───────────────────────────────────────┐
│                  Frontend Service                          │
│  ┌─────────────────────────────────────────────────────────┐│
│  │          React Application (Port 3000)                 ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────┴───────────────────────────────────────┐
│                  Backend Service                           │
│  ┌─────────────────────────────────────────────────────────┐│
│  │       FastAPI + AI Agents (Port 7777)                  ││
│  │  ┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ││
│  │  │ Browser Agent │ │ Coder Agent   │ │ File Agent    │ ││
│  │  └───────────────┘ └───────────────┘ └───────────────┘ ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────┴───────────────────────────────────────┐
│                Support Services                            │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │    SearXNG      │ │     Redis       │ │  LLM Server     ││
│  │  (Port 8080)    │ │  (Port 6379)    │ │ (Port 11434)    ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Core Components

1. **Frontend**: React-based web interface
2. **Backend**: FastAPI server with AI agent orchestration
3. **SearXNG**: Private search engine
4. **Redis**: Caching and session storage
5. **LLM Server**: Local or cloud-based language model inference

## Helm Chart Deployment (Recommended)

### Quick Start with Helm

For the fastest and most reliable cloud deployment, use our production-ready Helm charts:

```bash
# Clone the repository
git clone <repository-url>
cd agenticseek/helm

# Install with default values
helm install agenticseek ./agenticseek

# Or install with custom configuration
helm install agenticseek ./agenticseek -f my-values.yaml
```

### Helm Benefits

- **Production-Ready**: Pre-configured for cloud environments
- **Auto-Scaling**: Built-in horizontal pod autoscaling
- **Security**: Network policies and security contexts
- **Monitoring**: Prometheus ServiceMonitor integration
- **TLS/SSL**: Automatic certificate management with cert-manager
- **Persistence**: Configurable storage for workspaces and data

### Complete Helm Installation

See our comprehensive [Helm Installation Guide](../helm/README.md) for:
- Prerequisites and dependencies
- Advanced configuration options
- Production deployment examples
- Monitoring and observability setup
- Security hardening guidelines
- Troubleshooting and maintenance

## Cloud Provider Deployment

### Amazon Web Services (AWS)

#### ECS (Elastic Container Service) Deployment

1. **Create ECS Cluster**

```bash
# Create ECS cluster
aws ecs create-cluster --cluster-name agenticseek-cluster

# Create task definition
aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json
```

**ecs-task-definition.json**:
```json
{
  "family": "agenticseek",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "executionRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "frontend",
      "image": "agenticseek-frontend:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "REACT_APP_BACKEND_URL",
          "value": "http://backend:7777"
        }
      ]
    },
    {
      "name": "backend",
      "image": "agenticseek-backend:latest",
      "portMappings": [
        {
          "containerPort": 7777,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "SEARXNG_URL",
          "value": "http://searxng:8080"
        },
        {
          "name": "REDIS_URL",
          "value": "redis://redis:6379/0"
        }
      ]
    },
    {
      "name": "searxng",
      "image": "searxng/searxng:latest",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ]
    },
    {
      "name": "redis",
      "image": "redis:7-alpine",
      "portMappings": [
        {
          "containerPort": 6379,
          "protocol": "tcp"
        }
      ]
    }
  ]
}
```

2. **Application Load Balancer Setup**

```bash
# Create Application Load Balancer
aws elbv2 create-load-balancer \
  --name agenticseek-alb \
  --subnets subnet-12345 subnet-67890 \
  --security-groups sg-12345

# Create target group
aws elbv2 create-target-group \
  --name agenticseek-targets \
  --protocol HTTP \
  --port 3000 \
  --vpc-id vpc-12345 \
  --target-type ip
```

#### EC2 Deployment

```bash
# Launch EC2 instance
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.large \
  --key-name your-key-pair \
  --security-group-ids sg-12345 \
  --subnet-id subnet-12345 \
  --user-data file://user-data.sh
```

**user-data.sh**:
```bash
#!/bin/bash
yum update -y
yum install -y docker git

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

systemctl start docker
systemctl enable docker

# Clone and deploy AgenticSeek
git clone https://github.com/Fosowl/agenticSeek.git
cd agenticSeek

# Configure environment
cp .env.example .env
sed -i 's/WORK_DIR=.*/WORK_DIR=\/opt\/workspace/' .env

# Start services
./start_services.sh full
```

### Google Cloud Platform (GCP)

#### Cloud Run Deployment

1. **Build and Push Images**

```bash
# Build images
docker build -f Dockerfile.backend -t gcr.io/PROJECT_ID/agenticseek-backend .
docker build -f frontend/Dockerfile.frontend -t gcr.io/PROJECT_ID/agenticseek-frontend ./frontend

# Push to Container Registry
docker push gcr.io/PROJECT_ID/agenticseek-backend
docker push gcr.io/PROJECT_ID/agenticseek-frontend
```

2. **Deploy Services**

```bash
# Deploy backend
gcloud run deploy agenticseek-backend \
  --image gcr.io/PROJECT_ID/agenticseek-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars SEARXNG_URL=https://searxng-service-url,REDIS_URL=redis://redis-service

# Deploy frontend
gcloud run deploy agenticseek-frontend \
  --image gcr.io/PROJECT_ID/agenticseek-frontend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars REACT_APP_BACKEND_URL=https://agenticseek-backend-url
```

#### GKE (Google Kubernetes Engine) Deployment

```bash
# Create GKE cluster
gcloud container clusters create agenticseek-cluster \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type e2-standard-4

# Get credentials
gcloud container clusters get-credentials agenticseek-cluster --zone us-central1-a
```

### Microsoft Azure

#### Container Instances Deployment

```bash
# Create resource group
az group create --name agenticseek-rg --location eastus

# Deploy container group
az container create \
  --resource-group agenticseek-rg \
  --name agenticseek-app \
  --image agenticseek-backend:latest \
  --cpu 2 \
  --memory 4 \
  --restart-policy Always \
  --ports 7777 3000 8080 6379
```

#### Azure Kubernetes Service (AKS)

```bash
# Create AKS cluster
az aks create \
  --resource-group agenticseek-rg \
  --name agenticseek-aks \
  --node-count 3 \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group agenticseek-rg --name agenticseek-aks
```

## Kubernetes Deployment

### Namespace and ConfigMap

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: agenticseek

---
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: agenticseek-config
  namespace: agenticseek
data:
  SEARXNG_BASE_URL: "http://searxng-service:8080"
  REDIS_URL: "redis://redis-service:6379/0"
  BACKEND_PORT: "7777"
```

### Secrets Management

```yaml
# secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: agenticseek-secrets
  namespace: agenticseek
type: Opaque
data:
  OPENAI_API_KEY: <base64-encoded-key>
  DEEPSEEK_API_KEY: <base64-encoded-key>
  SEARXNG_SECRET_KEY: <base64-encoded-key>
```

### Redis Deployment

```yaml
# redis-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: agenticseek
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"

---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: agenticseek
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
```

### SearXNG Deployment

```yaml
# searxng-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: searxng
  namespace: agenticseek
spec:
  replicas: 1
  selector:
    matchLabels:
      app: searxng
  template:
    metadata:
      labels:
        app: searxng
    spec:
      containers:
      - name: searxng
        image: searxng/searxng:latest
        ports:
        - containerPort: 8080
        env:
        - name: SEARXNG_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: agenticseek-secrets
              key: SEARXNG_SECRET_KEY
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"

---
apiVersion: v1
kind: Service
metadata:
  name: searxng-service
  namespace: agenticseek
spec:
  selector:
    app: searxng
  ports:
  - port: 8080
    targetPort: 8080
```

### Backend Deployment

```yaml
# backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: agenticseek
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: agenticseek-backend:latest
        ports:
        - containerPort: 7777
        env:
        - name: SEARXNG_URL
          valueFrom:
            configMapKeyRef:
              name: agenticseek-config
              key: SEARXNG_BASE_URL
        - name: REDIS_URL
          valueFrom:
            configMapKeyRef:
              name: agenticseek-config
              key: REDIS_URL
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: agenticseek-secrets
              key: OPENAI_API_KEY
              optional: true
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
        volumeMounts:
        - name: workspace
          mountPath: /opt/workspace
      volumes:
      - name: workspace
        persistentVolumeClaim:
          claimName: workspace-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: agenticseek
spec:
  selector:
    app: backend
  ports:
  - port: 7777
    targetPort: 7777
  type: ClusterIP
```

### Frontend Deployment

```yaml
# frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: agenticseek
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: agenticseek-frontend:latest
        ports:
        - containerPort: 3000
        env:
        - name: REACT_APP_BACKEND_URL
          value: "http://backend-service:7777"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"

---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: agenticseek
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 3000
  type: LoadBalancer
```

### Persistent Volume

```yaml
# pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: workspace-pvc
  namespace: agenticseek
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard
```

### Ingress Configuration

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: agenticseek-ingress
  namespace: agenticseek
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
spec:
  tls:
  - hosts:
    - agenticseek.yourdomain.com
    secretName: agenticseek-tls
  rules:
  - host: agenticseek.yourdomain.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 7777
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

### Deployment Commands

```bash
# Apply all configurations
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secrets.yaml
kubectl apply -f pvc.yaml
kubectl apply -f redis-deployment.yaml
kubectl apply -f searxng-deployment.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f ingress.yaml

# Check deployment status
kubectl get pods -n agenticseek
kubectl get services -n agenticseek
kubectl get ingress -n agenticseek
```

## Docker Cloud Deployment

### Docker Swarm

1. **Initialize Swarm**

```bash
# Initialize swarm
docker swarm init

# Create overlay network
docker network create -d overlay agenticseek-net
```

2. **Docker Stack File**

```yaml
# docker-stack.yml
version: '3.8'

services:
  frontend:
    image: agenticseek-frontend:latest
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_BACKEND_URL=http://backend:7777
    networks:
      - agenticseek-net
    deploy:
      replicas: 2
      placement:
        constraints:
          - node.role == worker

  backend:
    image: agenticseek-backend:latest
    ports:
      - "7777:7777"
    environment:
      - SEARXNG_URL=http://searxng:8080
      - REDIS_URL=redis://redis:6379/0
    volumes:
      - workspace:/opt/workspace
    networks:
      - agenticseek-net
    deploy:
      replicas: 2
      placement:
        constraints:
          - node.role == worker

  searxng:
    image: searxng/searxng:latest
    ports:
      - "8080:8080"
    environment:
      - SEARXNG_SECRET_KEY=${SEARXNG_SECRET_KEY}
    networks:
      - agenticseek-net
    deploy:
      replicas: 1

  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data
    networks:
      - agenticseek-net
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager

volumes:
  redis-data:
  workspace:

networks:
  agenticseek-net:
    driver: overlay
    attachable: true
```

3. **Deploy Stack**

```bash
# Deploy the stack
docker stack deploy -c docker-stack.yml agenticseek

# Check services
docker service ls
docker stack ps agenticseek
```

## Environment Configuration

### Cloud Environment Variables

```bash
# Essential cloud configuration
DEPLOYMENT_MODE=cloud
CLOUD_PROVIDER=aws|gcp|azure
ENVIRONMENT=production|staging|development

# Database connections
REDIS_URL=redis://cloud-redis-host:6379/0
DATABASE_URL=postgresql://user:pass@cloud-db-host:5432/db

# External services
SEARXNG_URL=http://searxng-service:8080
BACKEND_URL=http://backend-service:7777

# Security
JWT_SECRET_KEY=your-jwt-secret
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Monitoring
ENABLE_MONITORING=true
LOG_LEVEL=INFO
SENTRY_DSN=your-sentry-dsn

# Storage
CLOUD_STORAGE_BUCKET=your-s3-bucket
WORKSPACE_STORAGE_TYPE=s3|gcs|azure_blob

# API Keys (Optional - for external LLM providers)
OPENAI_API_KEY=optional
ANTHROPIC_API_KEY=optional
GOOGLE_API_KEY=optional
```

### Dynamic Configuration

```python
# config_manager.py
import os
from typing import Dict, Any

class CloudConfigManager:
    def __init__(self):
        self.config = self._load_config()
    
    def _load_config(self) -> Dict[str, Any]:
        """Load configuration from environment and cloud services"""
        config = {
            'deployment_mode': os.getenv('DEPLOYMENT_MODE', 'local'),
            'cloud_provider': os.getenv('CLOUD_PROVIDER'),
            'redis_url': os.getenv('REDIS_URL'),
            'searxng_url': os.getenv('SEARXNG_URL'),
            'cors_origins': os.getenv('CORS_ORIGINS', '').split(','),
            'log_level': os.getenv('LOG_LEVEL', 'INFO'),
        }
        
        # Load cloud-specific configurations
        if config['cloud_provider'] == 'aws':
            config.update(self._load_aws_config())
        elif config['cloud_provider'] == 'gcp':
            config.update(self._load_gcp_config())
        elif config['cloud_provider'] == 'azure':
            config.update(self._load_azure_config())
            
        return config
    
    def _load_aws_config(self) -> Dict[str, Any]:
        """Load AWS-specific configuration"""
        return {
            'aws_region': os.getenv('AWS_REGION', 'us-east-1'),
            's3_bucket': os.getenv('S3_BUCKET'),
            'parameter_store_prefix': os.getenv('PARAMETER_STORE_PREFIX', '/agenticseek/'),
        }
    
    def _load_gcp_config(self) -> Dict[str, Any]:
        """Load GCP-specific configuration"""
        return {
            'gcp_project': os.getenv('GCP_PROJECT'),
            'gcs_bucket': os.getenv('GCS_BUCKET'),
            'secret_manager_prefix': os.getenv('SECRET_MANAGER_PREFIX', 'agenticseek-'),
        }
    
    def _load_azure_config(self) -> Dict[str, Any]:
        """Load Azure-specific configuration"""
        return {
            'azure_subscription': os.getenv('AZURE_SUBSCRIPTION_ID'),
            'storage_account': os.getenv('AZURE_STORAGE_ACCOUNT'),
            'key_vault_url': os.getenv('AZURE_KEY_VAULT_URL'),
        }
```

## Security Considerations

### Network Security

1. **VPC/Virtual Network Configuration**

```bash
# AWS VPC setup
aws ec2 create-vpc --cidr-block 10.0.0.0/16
aws ec2 create-subnet --vpc-id vpc-12345 --cidr-block 10.0.1.0/24
aws ec2 create-internet-gateway
aws ec2 attach-internet-gateway --internet-gateway-id igw-12345 --vpc-id vpc-12345
```

2. **Security Groups/Firewall Rules**

```yaml
# AWS Security Group (CloudFormation)
SecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    GroupDescription: AgenticSeek Security Group
    VpcId: !Ref VPC
    SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 443
        ToPort: 443
        CidrIp: 0.0.0.0/0
      - IpProtocol: tcp
        FromPort: 80
        ToPort: 80
        CidrIp: 0.0.0.0/0
      - IpProtocol: tcp
        FromPort: 3000
        ToPort: 3000
        SourceSecurityGroupId: !Ref LoadBalancerSecurityGroup
```

### Secrets Management

1. **AWS Secrets Manager**

```python
import boto3
import json

def get_secret(secret_name: str) -> dict:
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])
```

2. **Azure Key Vault**

```python
from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential

def get_azure_secret(vault_url: str, secret_name: str) -> str:
    credential = DefaultAzureCredential()
    client = SecretClient(vault_url=vault_url, credential=credential)
    secret = client.get_secret(secret_name)
    return secret.value
```

3. **GCP Secret Manager**

```python
from google.cloud import secretmanager

def get_gcp_secret(project_id: str, secret_id: str) -> str:
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode("UTF-8")
```

### SSL/TLS Configuration

```yaml
# Let's Encrypt with cert-manager
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

## Monitoring & Logging

### Prometheus and Grafana

```yaml
# prometheus-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'agenticseek-backend'
      static_configs:
      - targets: ['backend-service:7777']
    - job_name: 'agenticseek-frontend'
      static_configs:
      - targets: ['frontend-service:3000']
```

### ELK Stack Integration

```yaml
# filebeat-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: filebeat-config
data:
  filebeat.yml: |
    filebeat.inputs:
    - type: container
      paths:
        - /var/log/containers/agenticseek*.log
    output.elasticsearch:
      hosts: ['elasticsearch:9200']
    setup.kibana:
      host: 'kibana:5601'
```

### Application Monitoring

```python
# monitoring.py
import time
import psutil
from prometheus_client import Counter, Histogram, Gauge, start_http_server

# Metrics
REQUEST_COUNT = Counter('agenticseek_requests_total', 'Total requests', ['method', 'endpoint'])
REQUEST_LATENCY = Histogram('agenticseek_request_duration_seconds', 'Request latency')
ACTIVE_CONNECTIONS = Gauge('agenticseek_active_connections', 'Active connections')
MEMORY_USAGE = Gauge('agenticseek_memory_usage_bytes', 'Memory usage')

class Monitor:
    def __init__(self, port: int = 8080):
        self.port = port
        start_http_server(port)
    
    def track_request(self, method: str, endpoint: str):
        REQUEST_COUNT.labels(method=method, endpoint=endpoint).inc()
    
    def track_latency(self, duration: float):
        REQUEST_LATENCY.observe(duration)
    
    def update_system_metrics(self):
        MEMORY_USAGE.set(psutil.virtual_memory().used)
        # Add more system metrics as needed
```

## Scaling & Performance

### Horizontal Pod Autoscaler

```yaml
# hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
  namespace: agenticseek
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Vertical Pod Autoscaler

```yaml
# vpa.yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: backend-vpa
  namespace: agenticseek
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: backend
      maxAllowed:
        cpu: 2
        memory: 4Gi
      minAllowed:
        cpu: 100m
        memory: 128Mi
```

### Load Testing

```python
# load_test.py
import asyncio
import aiohttp
import time
from concurrent.futures import ThreadPoolExecutor

async def test_endpoint(session, url, payload):
    async with session.post(url, json=payload) as response:
        return await response.json()

async def load_test(url: str, concurrent_requests: int, total_requests: int):
    payload = {"query": "Test query for load testing"}
    
    async with aiohttp.ClientSession() as session:
        start_time = time.time()
        
        # Create semaphore to limit concurrent requests
        semaphore = asyncio.Semaphore(concurrent_requests)
        
        async def bounded_test():
            async with semaphore:
                return await test_endpoint(session, url, payload)
        
        # Execute all requests
        tasks = [bounded_test() for _ in range(total_requests)]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        end_time = time.time()
        duration = end_time - start_time
        
        # Calculate metrics
        successful = sum(1 for r in results if not isinstance(r, Exception))
        failed = len(results) - successful
        rps = total_requests / duration
        
        print(f"Total requests: {total_requests}")
        print(f"Successful: {successful}")
        print(f"Failed: {failed}")
        print(f"Duration: {duration:.2f}s")
        print(f"Requests per second: {rps:.2f}")

if __name__ == "__main__":
    asyncio.run(load_test("http://your-domain.com/api/query", 50, 1000))
```

## CI/CD Pipeline

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy to Cloud

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.10'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
    
    - name: Run tests
      run: |
        python -m pytest tests/
    
    - name: Build Docker images
      run: |
        docker build -f Dockerfile.backend -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-backend:${{ github.sha }} .
        docker build -f frontend/Dockerfile.frontend -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-frontend:${{ github.sha }} ./frontend
    
    - name: Log in to Container Registry
      if: github.event_name != 'pull_request'
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Push Docker images
      if: github.event_name != 'pull_request'
      run: |
        docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-backend:${{ github.sha }}
        docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-frontend:${{ github.sha }}

  deploy-staging:
    needs: build-and-test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: staging
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure kubectl
      run: |
        echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > kubeconfig
        export KUBECONFIG=kubeconfig
    
    - name: Deploy to staging
      run: |
        sed -i 's|IMAGE_TAG|${{ github.sha }}|g' k8s/*.yaml
        kubectl apply -f k8s/ -n agenticseek-staging
        kubectl rollout status deployment/backend -n agenticseek-staging
        kubectl rollout status deployment/frontend -n agenticseek-staging

  deploy-production:
    needs: build-and-test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure kubectl
      run: |
        echo "${{ secrets.PROD_KUBE_CONFIG }}" | base64 -d > kubeconfig
        export KUBECONFIG=kubeconfig
    
    - name: Deploy to production
      run: |
        sed -i 's|IMAGE_TAG|${{ github.sha }}|g' k8s/*.yaml
        kubectl apply -f k8s/ -n agenticseek-production
        kubectl rollout status deployment/backend -n agenticseek-production
        kubectl rollout status deployment/frontend -n agenticseek-production
```

### GitLab CI/CD

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy-staging
  - deploy-production

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -f Dockerfile.backend -t $CI_REGISTRY_IMAGE/backend:$CI_COMMIT_SHA .
    - docker build -f frontend/Dockerfile.frontend -t $CI_REGISTRY_IMAGE/frontend:$CI_COMMIT_SHA ./frontend
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker push $CI_REGISTRY_IMAGE/backend:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE/frontend:$CI_COMMIT_SHA

test:
  stage: test
  image: python:3.10
  script:
    - pip install -r requirements.txt
    - python -m pytest tests/

deploy-staging:
  stage: deploy-staging
  image: bitnami/kubectl:latest
  environment:
    name: staging
    url: https://staging.agenticseek.com
  script:
    - kubectl config use-context staging
    - sed -i "s|IMAGE_TAG|$CI_COMMIT_SHA|g" k8s/*.yaml
    - kubectl apply -f k8s/ -n agenticseek-staging
  only:
    - main

deploy-production:
  stage: deploy-production
  image: bitnami/kubectl:latest
  environment:
    name: production
    url: https://agenticseek.com
  script:
    - kubectl config use-context production
    - sed -i "s|IMAGE_TAG|$CI_COMMIT_SHA|g" k8s/*.yaml
    - kubectl apply -f k8s/ -n agenticseek-production
  when: manual
  only:
    - main
```

## Troubleshooting

### Common Issues

#### 1. Container Startup Issues

```bash
# Check pod logs
kubectl logs -f deployment/backend -n agenticseek

# Check events
kubectl get events -n agenticseek --sort-by='.lastTimestamp'

# Debug container
kubectl exec -it backend-pod-name -n agenticseek -- /bin/bash
```

#### 2. Network Connectivity Issues

```bash
# Test service connectivity
kubectl run test-pod --image=busybox -it --rm -- nslookup backend-service.agenticseek.svc.cluster.local

# Check ingress
kubectl describe ingress agenticseek-ingress -n agenticseek

# Test external connectivity
curl -I https://your-domain.com
```

#### 3. Resource Issues

```bash
# Check resource usage
kubectl top pods -n agenticseek
kubectl top nodes

# Check resource limits
kubectl describe pod backend-pod-name -n agenticseek | grep -A 5 Requests
```

#### 4. Storage Issues

```bash
# Check PVC status
kubectl get pvc -n agenticseek

# Check storage class
kubectl get storageclass

# Debug volume mounts
kubectl exec -it backend-pod-name -n agenticseek -- df -h
```

### Performance Troubleshooting

```python
# performance_debug.py
import psutil
import time
import logging
from typing import Dict, Any

class PerformanceMonitor:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
    
    def system_health_check(self) -> Dict[str, Any]:
        """Check system health metrics"""
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        health_data = {
            'cpu_usage': cpu_percent,
            'memory_usage': memory.percent,
            'memory_available': memory.available,
            'disk_usage': disk.percent,
            'disk_free': disk.free,
            'timestamp': time.time()
        }
        
        # Log warnings for high usage
        if cpu_percent > 80:
            self.logger.warning(f"High CPU usage: {cpu_percent}%")
        if memory.percent > 85:
            self.logger.warning(f"High memory usage: {memory.percent}%")
        if disk.percent > 90:
            self.logger.warning(f"High disk usage: {disk.percent}%")
        
        return health_data
    
    def network_connectivity_check(self, endpoints: list) -> Dict[str, bool]:
        """Check network connectivity to important endpoints"""
        import requests
        results = {}
        
        for endpoint in endpoints:
            try:
                response = requests.get(endpoint, timeout=5)
                results[endpoint] = response.status_code == 200
            except Exception as e:
                self.logger.error(f"Failed to connect to {endpoint}: {e}")
                results[endpoint] = False
        
        return results
```

### Log Analysis

```bash
# Search for errors in logs
kubectl logs -f deployment/backend -n agenticseek | grep -i error

# Get logs from all containers in a pod
kubectl logs backend-pod-name -n agenticseek --all-containers

# Export logs for analysis
kubectl logs deployment/backend -n agenticseek --since=1h > backend-logs.txt
```

### Health Checks

```python
# health_check.py
from fastapi import FastAPI, HTTPException
import redis
import requests

app = FastAPI()

@app.get("/health")
async def health_check():
    """Comprehensive health check endpoint"""
    health_status = {
        "status": "healthy",
        "checks": {
            "redis": False,
            "searxng": False,
            "disk_space": False,
            "memory": False
        }
    }
    
    try:
        # Check Redis connection
        r = redis.Redis(host='redis-service', port=6379, decode_responses=True)
        r.ping()
        health_status["checks"]["redis"] = True
    except Exception as e:
        health_status["checks"]["redis"] = False
        health_status["status"] = "unhealthy"
    
    try:
        # Check SearXNG
        response = requests.get("http://searxng-service:8080", timeout=5)
        health_status["checks"]["searxng"] = response.status_code == 200
    except Exception as e:
        health_status["checks"]["searxng"] = False
        health_status["status"] = "unhealthy"
    
    # Check system resources
    import psutil
    disk_usage = psutil.disk_usage('/').percent
    memory_usage = psutil.virtual_memory().percent
    
    health_status["checks"]["disk_space"] = disk_usage < 90
    health_status["checks"]["memory"] = memory_usage < 90
    
    if disk_usage >= 90 or memory_usage >= 90:
        health_status["status"] = "unhealthy"
    
    if health_status["status"] == "unhealthy":
        raise HTTPException(status_code=503, detail=health_status)
    
    return health_status
```

---

## Conclusion

This comprehensive cloud deployment guide provides everything needed to deploy AgenticSeek in production cloud environments. The configurations are battle-tested and follow cloud-native best practices for security, scalability, and reliability.

### Key Takeaways

1. **Multi-Cloud Support**: Deploy on AWS, GCP, or Azure with provided configurations
2. **Kubernetes-Native**: Full Kubernetes support with auto-scaling and monitoring
3. **Security-First**: Comprehensive security configurations and best practices
4. **Production-Ready**: Monitoring, logging, and CI/CD pipeline integration
5. **Scalable**: Horizontal and vertical scaling configurations included

### Next Steps

1. Choose your preferred cloud provider and deployment method
2. Customize the configurations for your specific requirements
3. Set up monitoring and alerting according to your needs
4. Implement the CI/CD pipeline for automated deployments
5. Configure backup and disaster recovery procedures

For additional support, refer to the main [README](../README.md) or join the [Discord community](https://discord.gg/8hGDaME3TC).
