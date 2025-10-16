#!/bin/bash
set -e

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

echo ""
echo "========================================="
echo "SUCCESS! Images available at:"
echo "  - ${REGISTRY}/${IMAGE_NAME}:latest"
echo "  - ${REGISTRY}/${IMAGE_NAME}:${SHORT_SHA}"
echo "========================================="
$()$(

  ## Why It Works Without the Flag:

  When you run
)configure-storage.sh$(, it creates)~/.config/containers/storage.conf$(
  with:
)$()
driver = "overlay"
