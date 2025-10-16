#!/bin/bash
echo "Cleaning up..."

# Logout from registry (don't fail if already logged out)
buildah logout "${REGISTRY}" 2>/dev/null || true

# Remove all containers
buildah rm --all 2>/dev/null || true

# Only remove the specific images we just built, NOT base images
SHORT_SHA=$(echo "${IMAGE_TAG:-${GITHUB_SHA}}" | cut -c1-7)
buildah rmi "${REGISTRY}/${IMAGE_NAME}:latest" 2>/dev/null || true
buildah rmi "${REGISTRY}/${IMAGE_NAME}:${SHORT_SHA}" 2>/dev/null || true

# DO NOT use 'buildah rmi --all' as it would remove cached base images!
echo "✓ Cleanup complete (preserved base image cache)"

# Show what's still cached
echo "Cached images after cleanup:"
buildah images 2>/dev/null || true
