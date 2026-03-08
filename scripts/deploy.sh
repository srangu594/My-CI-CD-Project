#!/bin/bash
# Usage: deploy.sh <image-repo> <image-tag> <container-name> <port>
set -euo pipefail
 
IMAGE_REPO=$1
IMAGE_TAG=$2
CONTAINER_NAME=$3
APP_PORT=$4
FULL_IMAGE="${IMAGE_REPO}:${IMAGE_TAG}"
 
echo "==> Pulling image: ${FULL_IMAGE}"
docker pull "${FULL_IMAGE}"
 
echo "==> Stopping existing container (if running)"
docker stop "${CONTAINER_NAME}" 2>/dev/null || true
docker rm   "${CONTAINER_NAME}" 2>/dev/null || true
 
echo "==> Starting new container"
docker run -d     --name "${CONTAINER_NAME}"     --restart unless-stopped     -p "${APP_PORT}:5000"     -e ENVIRONMENT=production     -e APP_VERSION="${IMAGE_TAG}"     "${FULL_IMAGE}"
 
echo "==> Container started: ${CONTAINER_NAME}"
docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}	{{.Status}}	{{.Ports}}"