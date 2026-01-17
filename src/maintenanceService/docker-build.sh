#!/bin/bash

# ===============================
# Maintenance Service Docker Build
# ===============================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
IMAGE_NAME="maintenance-service"
DOCKER_HUB_USERNAME="${DOCKER_HUB_USERNAME:-harinejan}"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Maintenance Service Build${NC}"
echo -e "${GREEN}================================${NC}"

# Check git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Get git info
GIT_COMMIT=$(git rev-parse --short HEAD)
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "")
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo -e "${YELLOW}Git Information:${NC}"
echo "  Commit: $GIT_COMMIT"
echo "  Branch: $GIT_BRANCH"
echo "  Tag: ${GIT_TAG:-none}"
echo "  Build Date: $BUILD_DATE"
echo ""

# Build
echo -e "${GREEN}Building Docker image...${NC}"
docker build \
  --label "git.commit=$GIT_COMMIT" \
  --label "git.branch=$GIT_BRANCH" \
  --label "git.tag=$GIT_TAG" \
  --label "build.date=$BUILD_DATE" \
  -t ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${GIT_COMMIT} \
  -t ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:latest \
  .

if [ -n "$GIT_TAG" ]; then
    echo -e "${GREEN}Tagging with git tag: $GIT_TAG${NC}"
    docker tag ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${GIT_COMMIT} ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${GIT_TAG}
fi

echo ""
echo -e "${GREEN}Build Complete!${NC}"
echo "Images created:"
echo "  ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:latest"
echo "  ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${GIT_COMMIT}"
if [ -n "$GIT_TAG" ]; then
    echo "  ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${GIT_TAG}"
fi
echo ""


