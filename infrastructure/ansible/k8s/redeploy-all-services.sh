#!/bin/bash

# ===============================
# Fleet Management - Redeploy All Services
# ===============================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
NAMESPACE="fleet-management"
DRY_RUN=false
SKIP_DATABASES=false
SKIP_KEYCLOAK=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --skip-databases)
      SKIP_DATABASES=true
      shift
      ;;
    --skip-keycloak)
      SKIP_KEYCLOAK=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --dry-run           Show what would be done"
      echo "  --skip-databases    Skip database deployments"
      echo "  --skip-keycloak     Skip Keycloak deployment"
      echo "  -h, --help          Show this help"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    echo -e "${CYAN}[DRY RUN] $@${NC}"
  else
    eval "$@"
  fi
}

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Fleet Management Deployment${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Namespace: $NAMESPACE"
echo "  Dry Run: $DRY_RUN"
echo "  Skip Databases: $SKIP_DATABASES"
echo "  Skip Keycloak: $SKIP_KEYCLOAK"
echo ""

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl not found${NC}"
    exit 1
fi

# Confirmation
if [ "$DRY_RUN" = false ]; then
  read -p "Deploy all services? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}Deployment cancelled${NC}"
      exit 0
  fi
fi

echo ""
echo -e "${GREEN}Step 1: Creating namespace${NC}"
run_cmd "kubectl apply -f ../../../src/vehicleService/k8s/namespace.yaml"

# Deploy databases
if [ "$SKIP_DATABASES" = false ]; then
  echo ""
  echo -e "${GREEN}Step 2: Deploying databases${NC}"
  run_cmd "kubectl apply -f ../../data/k8s/postgres-vehicle.yaml"
  run_cmd "kubectl apply -f ../../data/k8s/postgres-maintenance.yaml"
  run_cmd "kubectl apply -f ../../data/k8s/postgres-driver.yaml"
  
  if [ "$DRY_RUN" = false ]; then
    echo "  Waiting for databases to be ready..."
    kubectl wait --for=condition=ready pod -l app=postgres-vehicle -n $NAMESPACE --timeout=120s || true
    kubectl wait --for=condition=ready pod -l app=postgres-maintenance -n $NAMESPACE --timeout=120s || true
    kubectl wait --for=condition=ready pod -l app=postgres-driver -n $NAMESPACE --timeout=120s || true
  fi
fi

# Deploy Keycloak
if [ "$SKIP_KEYCLOAK" = false ]; then
  echo ""
  echo -e "${GREEN}Step 3: Deploying Keycloak${NC}"
  run_cmd "kubectl apply -f ../../identity/k8s/keycloak.yaml"
  
  if [ "$DRY_RUN" = false ]; then
    echo "  Waiting for Keycloak to be ready..."
    kubectl wait --for=condition=ready pod -l app=keycloak -n $NAMESPACE --timeout=180s || true
  fi
fi

echo ""
echo -e "${GREEN}Step 4: Deploying Vehicle Service${NC}"
run_cmd "kubectl apply -k ../../../src/vehicleService/k8s/"

echo ""
echo -e "${GREEN}Step 5: Deploying Maintenance Service${NC}"
run_cmd "kubectl apply -k ../../../src/maintenanceService/k8s/"

echo ""
echo -e "${GREEN}Step 6: Deploying Driver Service${NC}"
run_cmd "kubectl apply -k ../../../src/DriverService/k8s/"

echo ""
echo -e "${GREEN}Step 7: Deploying Frontend${NC}"
run_cmd "kubectl apply -k ../../../fleet-management-app/k8s/"

if [ "$DRY_RUN" = false ]; then
  echo ""
  echo -e "${GREEN}Step 8: Waiting for services to be ready${NC}"
  
  echo "  Waiting for Vehicle Service..."
  kubectl wait --for=condition=available --timeout=300s deployment/vehicle-service -n $NAMESPACE || true
  
  echo "  Waiting for Maintenance Service..."
  kubectl wait --for=condition=available --timeout=300s deployment/maintenance-service -n $NAMESPACE || true
  
  echo "  Waiting for Driver Service..."
  kubectl wait --for=condition=available --timeout=300s deployment/driver-service -n $NAMESPACE || true
  
  echo "  Waiting for Frontend..."
  kubectl wait --for=condition=available --timeout=300s deployment/fleet-frontend -n $NAMESPACE || true
  
  echo ""
  echo -e "${GREEN}Step 9: Deployment Status${NC}"
  kubectl get pods -n $NAMESPACE
  echo ""
  kubectl get svc -n $NAMESPACE
fi

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

if [ "$DRY_RUN" = false ]; then
  echo -e "${YELLOW}Useful commands:${NC}"
  echo "  View all pods:        kubectl get pods -n $NAMESPACE"
  echo "  View all services:    kubectl get svc -n $NAMESPACE"
  echo "  View logs:            kubectl logs -f deployment/<service-name> -n $NAMESPACE"
  echo "  Check Istio:          kubectl get virtualservices,destinationrules -n $NAMESPACE"
  echo ""
fi


