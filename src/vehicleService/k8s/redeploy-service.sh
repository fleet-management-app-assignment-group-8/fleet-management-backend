#!/bin/bash

# ===============================
# Vehicle Service Redeploy Script
# ===============================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

NAMESPACE="fleet-management"
SERVICE_NAME="vehicle-service"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
  esac
done

run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY RUN] $@${NC}"
  else
    eval "$@"
  fi
}

echo -e "${GREEN}Redeploying ${SERVICE_NAME}...${NC}"

if [ "$DRY_RUN" = false ]; then
  read -p "Continue? (y/N) " -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Yy]$ ]] && echo "Cancelled" && exit 0
fi

run_cmd "kubectl delete deployment $SERVICE_NAME -n $NAMESPACE --ignore-not-found=true"
run_cmd "kubectl apply -k ."

if [ "$DRY_RUN" = false ]; then
  kubectl wait --for=condition=available --timeout=300s deployment/$SERVICE_NAME -n $NAMESPACE
  kubectl get pods -n $NAMESPACE -l app=$SERVICE_NAME
fi

echo -e "${GREEN}Redeploy complete!${NC}"


