# AgenticSeek Helm Chart Makefile
# Provides convenient commands for managing the Helm deployment

.PHONY: help install upgrade uninstall status logs port-forward lint test clean

# Default values
RELEASE_NAME ?= agenticseek
NAMESPACE ?= default
VALUES_FILE ?= values.yaml
CHART_DIR ?= ./agenticseek

help: ## Show this help message
	@echo "AgenticSeek Helm Chart Management"
	@echo ""
	@echo "Usage: make [command] [options]"
	@echo ""
	@echo "Commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Options:"
	@echo "  RELEASE_NAME    Helm release name (default: agenticseek)"
	@echo "  NAMESPACE       Kubernetes namespace (default: default)"
	@echo "  VALUES_FILE     Values file to use (default: values.yaml)"
	@echo ""
	@echo "Examples:"
	@echo "  make install VALUES_FILE=prod-values.yaml NAMESPACE=production"
	@echo "  make upgrade RELEASE_NAME=my-agenticseek"
	@echo "  make logs NAMESPACE=production"

install: ## Install AgenticSeek using Helm
	@echo "Installing AgenticSeek..."
	helm install $(RELEASE_NAME) $(CHART_DIR) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		-f $(VALUES_FILE)
	@echo "Installation complete!"
	@echo "Access your deployment with: make status"

upgrade: ## Upgrade existing AgenticSeek deployment
	@echo "Upgrading AgenticSeek..."
	helm upgrade $(RELEASE_NAME) $(CHART_DIR) \
		--namespace $(NAMESPACE) \
		-f $(VALUES_FILE)
	@echo "Upgrade complete!"

uninstall: ## Uninstall AgenticSeek deployment
	@echo "Uninstalling AgenticSeek..."
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE)
	@echo "Uninstall complete!"

status: ## Show deployment status
	@echo "Helm Release Status:"
	helm status $(RELEASE_NAME) --namespace $(NAMESPACE)
	@echo ""
	@echo "Pod Status:"
	kubectl get pods -n $(NAMESPACE) -l app.kubernetes.io/instance=$(RELEASE_NAME)
	@echo ""
	@echo "Service Status:"
	kubectl get svc -n $(NAMESPACE) -l app.kubernetes.io/instance=$(RELEASE_NAME)

logs: ## Show logs from all components
	@echo "Backend Logs:"
	kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/instance=$(RELEASE_NAME),app.kubernetes.io/component=backend --tail=100
	@echo ""
	@echo "Frontend Logs:"
	kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/instance=$(RELEASE_NAME),app.kubernetes.io/component=frontend --tail=100
	@echo ""
	@echo "SearXNG Logs:"
	kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/instance=$(RELEASE_NAME),app.kubernetes.io/component=searxng --tail=100

logs-backend: ## Show backend logs
	kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/instance=$(RELEASE_NAME),app.kubernetes.io/component=backend -f

logs-frontend: ## Show frontend logs
	kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/instance=$(RELEASE_NAME),app.kubernetes.io/component=frontend -f

logs-searxng: ## Show SearXNG logs
	kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/instance=$(RELEASE_NAME),app.kubernetes.io/component=searxng -f

logs-redis: ## Show Redis logs
	kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/instance=$(RELEASE_NAME),app.kubernetes.io/component=redis -f

port-forward: ## Port forward to access services locally
	@echo "Starting port forwarding..."
	@echo "Frontend will be available at: http://localhost:3000"
	@echo "Backend will be available at: http://localhost:7777"
	@echo "Press Ctrl+C to stop"
	kubectl port-forward -n $(NAMESPACE) svc/$(RELEASE_NAME)-frontend 3000:80 &
	kubectl port-forward -n $(NAMESPACE) svc/$(RELEASE_NAME)-backend 7777:7777

port-forward-backend: ## Port forward to backend only
	@echo "Backend available at: http://localhost:7777"
	kubectl port-forward -n $(NAMESPACE) svc/$(RELEASE_NAME)-backend 7777:7777

port-forward-frontend: ## Port forward to frontend only
	@echo "Frontend available at: http://localhost:3000"
	kubectl port-forward -n $(NAMESPACE) svc/$(RELEASE_NAME)-frontend 3000:80

lint: ## Lint the Helm chart
	@echo "Linting Helm chart..."
	helm lint $(CHART_DIR)

test: ## Run Helm tests
	@echo "Running Helm tests..."
	helm test $(RELEASE_NAME) --namespace $(NAMESPACE)

dry-run: ## Perform a dry run installation
	@echo "Performing dry run..."
	helm install $(RELEASE_NAME) $(CHART_DIR) \
		--namespace $(NAMESPACE) \
		-f $(VALUES_FILE) \
		--dry-run --debug

template: ## Generate Kubernetes manifests
	@echo "Generating Kubernetes manifests..."
	helm template $(RELEASE_NAME) $(CHART_DIR) \
		--namespace $(NAMESPACE) \
		-f $(VALUES_FILE)

values: ## Show current values
	@echo "Current Helm values:"
	helm get values $(RELEASE_NAME) --namespace $(NAMESPACE)

rollback: ## Rollback to previous release
	@echo "Rolling back to previous release..."
	helm rollback $(RELEASE_NAME) --namespace $(NAMESPACE)

clean: ## Clean up resources
	@echo "Cleaning up..."
	kubectl delete pvc -n $(NAMESPACE) -l app.kubernetes.io/instance=$(RELEASE_NAME) || true
	kubectl delete secret -n $(NAMESPACE) -l app.kubernetes.io/instance=$(RELEASE_NAME) || true
	@echo "Cleanup complete!"

deps: ## Install dependencies (nginx-ingress, cert-manager)
	@echo "Installing dependencies..."
	@echo "Installing NGINX Ingress Controller..."
	helm upgrade --install ingress-nginx ingress-nginx \
		--repo https://kubernetes.github.io/ingress-nginx \
		--namespace ingress-nginx --create-namespace
	@echo "Installing Cert-Manager..."
	helm upgrade --install cert-manager jetstack/cert-manager \
		--repo https://charts.jetstack.io \
		--namespace cert-manager \
		--create-namespace \
		--version v1.13.0 \
		--set installCRDs=true
	@echo "Dependencies installed!"

backup: ## Backup persistent data
	@echo "Creating backup..."
	kubectl create job -n $(NAMESPACE) backup-$(shell date +%Y%m%d-%H%M%S) \
		--image=alpine:latest \
		-- sh -c "apk add --no-cache rsync && rsync -av /data/ /backup/"

# Development helpers
dev-install: ## Install for development
	make install VALUES_FILE=dev-values.yaml NAMESPACE=agenticseek-dev

prod-install: ## Install for production
	make install VALUES_FILE=prod-values.yaml NAMESPACE=agenticseek-prod

staging-install: ## Install for staging
	make install VALUES_FILE=staging-values.yaml NAMESPACE=agenticseek-staging

# Monitoring helpers
top: ## Show resource usage
	@echo "Resource Usage:"
	kubectl top pods -n $(NAMESPACE) -l app.kubernetes.io/instance=$(RELEASE_NAME)

describe: ## Describe all resources
	@echo "Describing all resources..."
	kubectl describe all -n $(NAMESPACE) -l app.kubernetes.io/instance=$(RELEASE_NAME)

events: ## Show recent events
	kubectl get events -n $(NAMESPACE) --sort-by='.lastTimestamp' | tail -20
