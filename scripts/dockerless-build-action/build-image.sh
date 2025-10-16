#!/bin/bash
set -e

echo "Building Docker image..."
echo "Current directory: $(pwd)"
echo "GITHUB_WORKSPACE: ${GITHUB_WORKSPACE}"

# Set storage configuration
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

# CRITICAL FIX: Make sure we're in the right directory
# GitHub Actions sets GITHUB_WORKSPACE to the checkout directory
if [ -n "${GITHUB_WORKSPACE}" ] && [ -d "${GITHUB_WORKSPACE}" ]; then
  cd "${GITHUB_WORKSPACE}"
  echo "Changed to workspace directory: $(pwd)"
fi

# Verify Dockerfile exists
if [ ! -f "${DOCKERFILE:-Dockerfile}" ]; then
  echo "ERROR: Dockerfile not found in $(pwd)"
  echo "Contents of current directory:"
  ls -la
  exit 1
fi

echo "Found Dockerfile at: $(pwd)/${DOCKERFILE:-Dockerfile}"

# Build target argument
TARGET_ARG=""
if [ -n "${BUILD_TARGET}" ]; then
  TARGET_ARG="--target ${BUILD_TARGET}"
  echo "Using build target: ${BUILD_TARGET}"
fi

# Build the image
buildah --storage-driver=overlay bud \
  --isolation=chroot \
  --format docker \
  -f ${DOCKERFILE:-Dockerfile} \
  ${TARGET_ARG} \
  -t "${REGISTRY}/${IMAGE_NAME}:latest" \
  -t "${REGISTRY}/${IMAGE_NAME}:${SHORT_SHA}" \
  --build-arg VERSION="${SHORT_SHA}" \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  --layers \
  .

echo "✓ Image built successfully"
