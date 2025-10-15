#!/bin/bash

echo "Cleaning up..."

# Logout from registry (don't fail if already logged out)
buildah logout "${REGISTRY}" 2>/dev/null || true

# Remove all containers
buildah rm --all 2>/dev/null || true

# Remove local test images to save space
buildah rmi "${REGISTRY}/${IMAGE_NAME}:latest" 2>/dev/null || true

echo "✓ Cleanup complete"
