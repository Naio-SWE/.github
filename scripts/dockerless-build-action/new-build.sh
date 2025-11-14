#!/bin/bash
set -e

echo "Building Docker image..."

# Use the dockerfile path from environment, default to 'Dockerfile'
DOCKERFILE="${DOCKERFILE:-Dockerfile}"

# Dockerfile should be in the checked-out repo (current directory)
if [ ! -f "$DOCKERFILE" ]; then
  echo "ERROR: Dockerfile not found at: $DOCKERFILE"
  echo "Current directory contents:"
  ls -la
  exit 1
fi

# Calculate tags
SHORT_SHA=$(echo "${IMAGE_TAG:-${GITHUB_SHA}}" | cut -c1-7)
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

# Build arguments
TAGS="-t ${REGISTRY}/${IMAGE_NAME}:latest -t ${REGISTRY}/${IMAGE_NAME}:${SHORT_SHA}"
TARGET_ARG=""

if [ -n "${BUILD_TARGET}" ]; then
  TARGET_ARG="--target ${BUILD_TARGET}"
fi

if [ -n "${CUSTOM_TAG}" ]; then
  TAGS="${TAGS} -t ${REGISTRY}/${IMAGE_NAME}:${CUSTOM_TAG}"
fi

# Build the image
echo "Building with tags: ${TAGS}"
buildah bud \
  --format docker \
  -f "$DOCKERFILE" \
  ${TARGET_ARG} \
  ${TAGS} \
  --build-arg VERSION="${SHORT_SHA}" \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  .

echo "✓ Build complete"
