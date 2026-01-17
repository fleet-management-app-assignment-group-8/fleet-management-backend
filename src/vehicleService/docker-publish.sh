#!/bin/bash

# ===============================
# Vehicle Service Docker Publish
# ===============================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
IMAGE_NAME="vehicle-service"
DOCKER_HUB_USERNAME="${DOCKER_HUB_USERNAME:-harinejan}"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Vehicle Service Publish${NC}"
echo -e "${GREEN}================================${NC}"

# Get git info
GIT_COMMIT=$(git rev-parse --short HEAD)
GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "")

echo "Publishing images for commit: $GIT_COMMIT"
if [ -n "$GIT_TAG" ]; then
    echo "Git tag: $GIT_TAG"
fi
echo ""

# Check if image exists
if ! docker image inspect ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${GIT_COMMIT} > /dev/null 2>&1; then
    echo -e "${RED}Error: Image not found. Run ./docker-build.sh first${NC}"
    exit 1
fi

# Confirmation
read -p "Push to Docker Hub? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Publish cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}Pushing images...${NC}"

docker push ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${GIT_COMMIT}
docker push ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:latest

if [ -n "$GIT_TAG" ]; then
    docker push ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${GIT_TAG}
fi

echo ""
echo -e "${GREEN}Publish Complete!${NC}"
echo "Docker Hub: https://hub.docker.com/r/${DOCKER_HUB_USERNAME}/${IMAGE_NAME}"
echo ""


