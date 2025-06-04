#!/bin/bash

# AgenticSeek Helm Deployment Validation Script
# This script validates that the Helm deployment is working correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
RELEASE_NAME="${RELEASE_NAME:-agenticseek}"
NAMESPACE="${NAMESPACE:-default}"
TIMEOUT="${TIMEOUT:-300}"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if helm is available
    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we can access the cluster
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot access Kubernetes cluster"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

check_helm_release() {
    log_info "Checking Helm release status..."
    
    if ! helm status "$RELEASE_NAME" -n "$NAMESPACE" &> /dev/null; then
        log_error "Helm release '$RELEASE_NAME' not found in namespace '$NAMESPACE'"
        exit 1
    fi
    
    local status=$(helm status "$RELEASE_NAME" -n "$NAMESPACE" -o json | jq -r '.info.status')
    if [ "$status" != "deployed" ]; then
        log_error "Helm release status is '$status', expected 'deployed'"
        exit 1
    fi
    
    log_info "Helm release is deployed successfully"
}

wait_for_pods() {
    log_info "Waiting for pods to be ready..."
    
    local components=("backend" "frontend" "searxng" "redis")
    
    for component in "${components[@]}"; do
        log_info "Waiting for $component pods..."
        if ! kubectl wait --for=condition=ready pod \
            -l app.kubernetes.io/instance="$RELEASE_NAME",app.kubernetes.io/component="$component" \
            -n "$NAMESPACE" \
            --timeout="${TIMEOUT}s"; then
            log_error "$component pods failed to become ready"
            return 1
        fi
        log_info "$component pods are ready"
    done
}

check_services() {
    log_info "Checking services..."
    
    local services=("backend" "frontend" "searxng" "redis")
    
    for service in "${services[@]}"; do
        local service_name="${RELEASE_NAME}-${service}"
        if ! kubectl get service "$service_name" -n "$NAMESPACE" &> /dev/null; then
            log_error "Service '$service_name' not found"
            return 1
        fi
        
        # Check if service has endpoints
        local endpoints=$(kubectl get endpoints "$service_name" -n "$NAMESPACE" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "")
        if [ -z "$endpoints" ]; then
            log_warn "Service '$service_name' has no endpoints"
        else
            log_info "Service '$service_name' is ready with endpoints"
        fi
    done
}

check_ingress() {
    log_info "Checking ingress..."
    
    local ingress_name="${RELEASE_NAME}"
    if kubectl get ingress "$ingress_name" -n "$NAMESPACE" &> /dev/null; then
        local hosts=$(kubectl get ingress "$ingress_name" -n "$NAMESPACE" -o jsonpath='{.spec.rules[*].host}')
        log_info "Ingress found with hosts: $hosts"
        
        # Check if ingress has address
        local address=$(kubectl get ingress "$ingress_name" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [ -z "$address" ]; then
            address=$(kubectl get ingress "$ingress_name" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
        fi
        
        if [ -n "$address" ]; then
            log_info "Ingress has address: $address"
        else
            log_warn "Ingress does not have an external address yet"
        fi
    else
        log_warn "Ingress not found - this might be expected if ingress is disabled"
    fi
}

check_persistence() {
    log_info "Checking persistent volumes..."
    
    local pvcs=$(kubectl get pvc -n "$NAMESPACE" -l app.kubernetes.io/instance="$RELEASE_NAME" -o name 2>/dev/null || echo "")
    if [ -n "$pvcs" ]; then
        for pvc in $pvcs; do
            local status=$(kubectl get "$pvc" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
            if [ "$status" = "Bound" ]; then
                log_info "PVC ${pvc#persistentvolumeclaim/} is bound"
            else
                log_warn "PVC ${pvc#persistentvolumeclaim/} is in status: $status"
            fi
        done
    else
        log_info "No persistent volumes found - this might be expected"
    fi
}

test_connectivity() {
    log_info "Testing internal connectivity..."
    
    # Get a backend pod to test from
    local backend_pod=$(kubectl get pods -n "$NAMESPACE" \
        -l app.kubernetes.io/instance="$RELEASE_NAME",app.kubernetes.io/component="backend" \
        -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$backend_pod" ]; then
        log_warn "No backend pod found for connectivity testing"
        return
    fi
    
    # Test Redis connectivity
    log_info "Testing Redis connectivity..."
    if kubectl exec -n "$NAMESPACE" "$backend_pod" -- \
        timeout 5 bash -c "echo 'PING' | nc ${RELEASE_NAME}-redis 6379" &> /dev/null; then
        log_info "Redis connectivity test passed"
    else
        log_warn "Redis connectivity test failed"
    fi
    
    # Test SearXNG connectivity
    log_info "Testing SearXNG connectivity..."
    if kubectl exec -n "$NAMESPACE" "$backend_pod" -- \
        timeout 5 curl -s "http://${RELEASE_NAME}-searxng:8080/" &> /dev/null; then
        log_info "SearXNG connectivity test passed"
    else
        log_warn "SearXNG connectivity test failed"
    fi
}

check_resources() {
    log_info "Checking resource usage..."
    
    if command -v kubectl &> /dev/null && kubectl top pods -n "$NAMESPACE" \
        -l app.kubernetes.io/instance="$RELEASE_NAME" &> /dev/null; then
        echo "Resource usage:"
        kubectl top pods -n "$NAMESPACE" -l app.kubernetes.io/instance="$RELEASE_NAME"
    else
        log_warn "Cannot get resource usage - metrics-server might not be available"
    fi
}

show_access_info() {
    log_info "Access information:"
    
    # Get ingress info
    local ingress_name="${RELEASE_NAME}"
    if kubectl get ingress "$ingress_name" -n "$NAMESPACE" &> /dev/null; then
        local hosts=$(kubectl get ingress "$ingress_name" -n "$NAMESPACE" -o jsonpath='{.spec.rules[*].host}')
        local tls=$(kubectl get ingress "$ingress_name" -n "$NAMESPACE" -o jsonpath='{.spec.tls[0].hosts[0]}' 2>/dev/null || echo "")
        
        if [ -n "$tls" ]; then
            echo "  Web UI: https://$hosts"
        else
            echo "  Web UI: http://$hosts"
        fi
    fi
    
    # Show port-forward commands
    echo "  Port-forward commands:"
    echo "    Frontend: kubectl port-forward -n $NAMESPACE svc/${RELEASE_NAME}-frontend 3000:80"
    echo "    Backend:  kubectl port-forward -n $NAMESPACE svc/${RELEASE_NAME}-backend 7777:7777"
}

print_summary() {
    log_info "Validation Summary:"
    echo "  Release Name: $RELEASE_NAME"
    echo "  Namespace: $NAMESPACE"
    echo "  Validation completed successfully!"
    echo ""
    show_access_info
}

main() {
    echo "AgenticSeek Helm Deployment Validation"
    echo "======================================="
    
    check_prerequisites
    check_helm_release
    wait_for_pods
    check_services
    check_ingress
    check_persistence
    test_connectivity
    check_resources
    
    echo ""
    print_summary
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Validates AgenticSeek Helm deployment"
    echo ""
    echo "Options:"
    echo "  -r, --release-name NAME    Helm release name (default: agenticseek)"
    echo "  -n, --namespace NAMESPACE  Kubernetes namespace (default: default)"
    echo "  -t, --timeout SECONDS      Timeout for pod readiness (default: 300)"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  RELEASE_NAME              Helm release name"
    echo "  NAMESPACE                 Kubernetes namespace"
    echo "  TIMEOUT                   Timeout for pod readiness"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Use defaults"
    echo "  $0 -r my-agenticseek -n production   # Custom release and namespace"
    echo "  RELEASE_NAME=test $0                 # Use environment variable"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--release-name)
            RELEASE_NAME="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if jq is available (optional but recommended)
if ! command -v jq &> /dev/null; then
    log_warn "jq is not installed - some checks may be limited"
fi

# Run main validation
main
