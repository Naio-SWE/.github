#!/bin/bash
set -e

echo "Building Docker image..."

# Force VFS storage driver and chroot isolation
export STORAGE_DRIVER=vfs
export BUILDAH_ISOLATION=chroot

SHORT_SHA=$(echo "${IMAGE_TAG:-${GITHUB_SHA}}" | cut -c1-7)
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

echo "Image: registry.yasp.localdomain:5050/${IMAGE_NAME}"
echo "Tags: latest, ${SHORT_SHA}"
echo "Build date: ${BUILD_DATE}"
echo "Storage driver: vfs"
echo "Isolation: chroot"

# Build with explicit VFS driver and chroot isolation
buildah --storage-driver=vfs bud \
  --isolation=chroot \
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
buildah --storage-driver=vfs images | grep "${IMAGE_NAME}" || true
