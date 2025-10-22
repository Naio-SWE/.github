#!/bin/bash

#build-image.sh
set -e

echo "========================================="
echo "DEBUG: Starting build-image.sh"
echo "========================================="

echo "1. ENVIRONMENT:"
echo "   PWD: $(pwd)"
echo "   GITHUB_WORKSPACE: ${GITHUB_WORKSPACE}"
echo "   DOCKERFILE: ${DOCKERFILE}"
echo "   BUILD_CONTEXT: ${BUILD_CONTEXT:-./}"

echo ""
echo "2. WORKSPACE CONTENTS:"
echo "   Contents of current directory ($(pwd)):"
ls -la

# Use BUILD_CONTEXT environment variable with fallback
BUILD_CONTEXT_DIR="${BUILD_CONTEXT:-.}"
DOCKERFILE_PATH="${DOCKERFILE:-Dockerfile}"

# Since caller must checkout, we expect files in workspace
# Check current directory first, then GITHUB_WORKSPACE
if [ -f "${DOCKERFILE_PATH}" ]; then
  DOCKERFILE_LOCATION="${DOCKERFILE_PATH}"
elif [ -f "${GITHUB_WORKSPACE}/${DOCKERFILE_PATH}" ]; then
  DOCKERFILE_LOCATION="${GITHUB_WORKSPACE}/${DOCKERFILE_PATH}"
elif [ -f "/__w/${GITHUB_REPOSITORY#*/}/${GITHUB_REPOSITORY#*/}/${DOCKERFILE_PATH}" ]; then
  # Fallback for GitHub Actions default checkout location
  DOCKERFILE_LOCATION="/__w/${GITHUB_REPOSITORY#*/}/${GITHUB_REPOSITORY#*/}/${DOCKERFILE_PATH}"
else
  echo "ERROR: Dockerfile not found at ${DOCKERFILE_PATH}"
  echo ""
  echo "The calling workflow MUST checkout code before calling this reusable workflow!"
  echo ""
  echo "Searched locations:"
  echo "  - ./${DOCKERFILE_PATH}"
  echo "  - ${GITHUB_WORKSPACE}/${DOCKERFILE_PATH}"
  echo "  - /__w/${GITHUB_REPOSITORY#*/}/${GITHUB_REPOSITORY#*/}/${DOCKERFILE_PATH}"
  echo ""
  echo "Current directory structure:"
  find . -type f -name "Dockerfile*" 2>/dev/null | head -10 || echo "No Dockerfiles found"
  exit 1
fi

echo "   Found Dockerfile at: $DOCKERFILE_LOCATION"

# Handle build context directory (relative to workspace)
if [ -d "${BUILD_CONTEXT_DIR}" ]; then
  BUILD_CONTEXT_PATH="${BUILD_CONTEXT_DIR}"
elif [ -d "${GITHUB_WORKSPACE}/${BUILD_CONTEXT_DIR}" ]; then
  BUILD_CONTEXT_PATH="${GITHUB_WORKSPACE}/${BUILD_CONTEXT_DIR}"
else
  echo "WARNING: Build context directory '${BUILD_CONTEXT_DIR}' not found, using current directory"
  BUILD_CONTEXT_PATH="."
fi

echo "   Using build context: $BUILD_CONTEXT_PATH"
echo "   Contents of build context directory:"
ls -la "$BUILD_CONTEXT_PATH" | head -10

echo ""
echo "3. BUILDING IMAGE:"
echo "   Command: buildah bud -f $DOCKERFILE_LOCATION $BUILD_CONTEXT_PATH"

SHORT_SHA=$(echo "${IMAGE_TAG:-${GITHUB_SHA}}" | cut -c1-7)
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

TARGET_ARG=""
if [ -n "${BUILD_TARGET}" ]; then
  TARGET_ARG="--target ${BUILD_TARGET}"
fi

TAGS="-t ${REGISTRY}/${IMAGE_NAME}:latest -t ${REGISTRY}/${IMAGE_NAME}:${SHORT_SHA}"

if [ -n "${CUSTOM_TAG}" ]; then
  echo "   Adding custom tag: ${CUSTOM_TAG}"
  TAGS="${TAGS} -t ${REGISTRY}/${IMAGE_NAME}:${CUSTOM_TAG}"
fi

echo "   Tags to be created:"
echo "     - ${REGISTRY}/${IMAGE_NAME}:latest"
echo "     - ${REGISTRY}/${IMAGE_NAME}:${SHORT_SHA}"
if [ -n "${CUSTOM_TAG}" ]; then
  echo "     - ${REGISTRY}/${IMAGE_NAME}:${CUSTOM_TAG}"
fi

buildah --storage-driver=${STORAGE_DRIVER:-overlay} bud \
  --isolation=${BUILDAH_ISOLATION:-chroot} \
  --format docker \
  -f "$DOCKERFILE_LOCATION" \
  ${TARGET_ARG} \
  ${TAGS} \
  --build-arg VERSION="${SHORT_SHA}" \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  --layers \
  --log-level=debug \
  "$BUILD_CONTEXT_PATH" 2>&1

BUILD_EXIT_CODE=$?
echo ""
echo "Build exit code: $BUILD_EXIT_CODE"

if [ $BUILD_EXIT_CODE -ne 0 ]; then
  echo "Build failed!"
  if [ $BUILD_EXIT_CODE -eq 125 ]; then
    echo "Exit code 125 means buildah runtime failure - usually can't find Dockerfile or context"
  fi
fi

exit $BUILD_EXIT_CODE
