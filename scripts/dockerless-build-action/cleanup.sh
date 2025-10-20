#!/bin/bash
echo "Cleaning up..."
#cleanup.sh

buildah logout "${REGISTRY}" 2>/dev/null || true
buildah rm --all 2>/dev/null || true

SHORT_SHA=$(echo "${IMAGE_TAG:-${GITHUB_SHA}}" | cut -c1-7)
buildah rmi "${REGISTRY}/${IMAGE_NAME}:latest" 2>/dev/null || true
buildah rmi "${REGISTRY}/${IMAGE_NAME}:${SHORT_SHA}" 2>/dev/null || true

# Remove custom tag if it was used
if [ -n "${CUSTOM_TAG}" ]; then
  buildah rmi "${REGISTRY}/${IMAGE_NAME}:${CUSTOM_TAG}" 2>/dev/null || true
fi

echo "✓ Cleanup complete (preserved base image cache)"
echo "Cached images after cleanup:"
buildah images 2>/dev/null || true
