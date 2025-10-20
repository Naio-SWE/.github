#!/bin/bash
set -e
#push-image.sh
echo "Pushing images to ${REGISTRY}..."

SHORT_SHA=$(echo "${IMAGE_TAG:-${GITHUB_SHA}}" | cut -c1-7)

# Push latest tag
echo "Pushing ${REGISTRY}/${IMAGE_NAME}:latest..."
buildah push \
  --storage-driver=overlay \
  --tls-verify=false \
  "${REGISTRY}/${IMAGE_NAME}:latest"
echo "✓ Pushed: ${REGISTRY}/${IMAGE_NAME}:latest"

# Push SHA tag
echo "Pushing ${REGISTRY}/${IMAGE_NAME}:${SHORT_SHA}..."
buildah push \
  --storage-driver=overlay \
  --tls-verify=false \
  "${REGISTRY}/${IMAGE_NAME}:${SHORT_SHA}"
echo "✓ Pushed: ${REGISTRY}/${IMAGE_NAME}:${SHORT_SHA}"

# Push custom tag if provided
if [ -n "${CUSTOM_TAG}" ]; then
  echo "Pushing ${REGISTRY}/${IMAGE_NAME}:${CUSTOM_TAG}..."
  buildah push \
    --storage-driver=overlay \
    --tls-verify=false \
    "${REGISTRY}/${IMAGE_NAME}:${CUSTOM_TAG}"
  echo "✓ Pushed: ${REGISTRY}/${IMAGE_NAME}:${CUSTOM_TAG}"
fi

echo ""
echo "========================================="
echo "SUCCESS! Images available at:"
echo "  - ${REGISTRY}/${IMAGE_NAME}:latest"
echo "  - ${REGISTRY}/${IMAGE_NAME}:${SHORT_SHA}"
if [ -n "${CUSTOM_TAG}" ]; then
  echo "  - ${REGISTRY}/${IMAGE_NAME}:${CUSTOM_TAG}"
fi
echo "========================================="
