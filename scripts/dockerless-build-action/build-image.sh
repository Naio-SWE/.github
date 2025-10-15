#!/bin/bash
set -e

echo "Building Docker image..."

# Get short commit SHA for tagging
SHORT_SHA=$(echo "${IMAGE_TAG:-${GITHUB_SHA}}" | cut -c1-7)
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

echo "Image: ${REGISTRY}/${IMAGE_NAME}"
echo "Tags: latest, ${SHORT_SHA}"
echo "Build date: ${BUILD_DATE}"

# Build the image with multiple tags
buildah bud \
  --format docker \
  -f Dockerfile.test \
  -t "${REGISTRY}/${IMAGE_NAME}:latest" \
  -t "${REGISTRY}/${IMAGE_NAME}:${SHORT_SHA}" \
  --build-arg VERSION="${SHORT_SHA}" \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  --layers \
  .

echo "✓ Image built successfully"
echo ""
echo "Built images:"
buildah images | grep "${IMAGE_NAME}" || true
