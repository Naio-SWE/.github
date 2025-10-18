#!/bin/bash
set -e

echo "Building Docker image (NO CACHE)..."

# Create a temporary storage directory for this build only
export TMPDIR=$(mktemp -d)
export BUILDAH_ISOLATION=chroot

SHORT_SHA=$(echo "${IMAGE_TAG:-${GITHUB_SHA}}" | cut -c1-7)

echo "Building fresh - no cache, no layers..."

# Build without ANY caching
buildah --root ${TMPDIR}/containers --runroot ${TMPDIR}/run \
  bud \
  --no-cache \
  --pull-always \
  --isolation=chroot \
  --format docker \
  -f ${DOCKERFILE:-Dockerfile} \
  ${TARGET_ARG:+--target ${BUILD_TARGET}} \
  -t "${REGISTRY}/${IMAGE_NAME}:latest" \
  -t "${REGISTRY}/${IMAGE_NAME}:${SHORT_SHA}" \
  .

# Clean up temp directory
rm -rf ${TMPDIR}
