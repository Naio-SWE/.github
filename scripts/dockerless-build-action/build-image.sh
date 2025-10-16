#!/bin/bash
set -e

echo "Building Docker image..."
export STORAGE_DRIVER=overlay
export BUILDAH_ISOLATION=chroot

SHORT_SHA=$(echo "${IMAGE_TAG:-${GITHUB_SHA}}" | cut -c1-7)
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

echo "Image: ${REGISTRY}/${IMAGE_NAME}"
echo "Tags: latest, ${SHORT_SHA}"
echo "Build date: ${BUILD_DATE}"
echo "Storage driver: overlay"
echo "Isolation: chroot"
echo "Dockerfile: ${DOCKERFILE:-Dockerfile}"
echo "Build target: ${BUILD_TARGET:-none}"

# Build target argument
TARGET_ARG=""
if [ -n "${BUILD_TARGET}" ]; then
  TARGET_ARG="--target ${BUILD_TARGET}"
  echo "Using build target: ${BUILD_TARGET}"
fi

DOCKERFILE_PATH="$(pwd)/${DOCKERFILE:-Dockerfile}"
BUILD_CONTEXT="$(pwd)"

echo "Using Dockerfile: ${DOCKERFILE_PATH}"
echo "Build context: ${BUILD_CONTEXT}"

# Check if Dockerfile exists
if [ ! -f "${DOCKERFILE_PATH}" ]; then
  echo "ERROR: Dockerfile not found at ${DOCKERFILE_PATH}"
  echo "Current directory contents:"
  ls -la
  exit 1
fi

buildah --storage-driver=overlay bud \
  --isolation=chroot \
  --format docker \
  -f "${DOCKERFILE_PATH}" \
  ${TARGET_ARG} \
  -t "${REGISTRY}/${IMAGE_NAME}:latest" \
  -t "${REGISTRY}/${IMAGE_NAME}:${SHORT_SHA}" \
  --build-arg VERSION="${SHORT_SHA}" \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  --layers \
  "${BUILD_CONTEXT}"

echo "✓ Image built successfully"
