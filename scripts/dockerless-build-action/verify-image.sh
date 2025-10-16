#!/bin/bash
set -e

echo "Verifying pushed image..."

# Remove local image first to ensure we're pulling from registry
buildah rmi "${REGISTRY}/${IMAGE_NAME}:latest" 2>/dev/null || true

# Try to pull the image back from registry
buildah pull \
  --tls-verify=false \
  "${REGISTRY}/${IMAGE_NAME}:latest"

echo "✓ Image verified - successfully pulled from registry"
