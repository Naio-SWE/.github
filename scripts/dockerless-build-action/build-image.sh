#!/bin/bash

#build-image.sh
set -e

echo "========================================="
echo "DEBUG: Starting build-image.sh"
echo "========================================="

# First, let's see where we actually are and what we have
echo "1. ENVIRONMENT:"
echo "   PWD: $(pwd)"
echo "   GITHUB_WORKSPACE: ${GITHUB_WORKSPACE}"
echo "   HOME: ${HOME}"
echo "   USER: $(whoami)"
echo "   HOSTNAME: $(hostname)"

echo ""
echo "2. FILESYSTEM EXPLORATION:"
echo "   Contents of current directory ($(pwd)):"
ls -la

echo ""
echo "   Does Dockerfile exist in current dir?"
if [ -f "Dockerfile" ]; then
  echo "   YES - Dockerfile found at $(pwd)/Dockerfile"
  echo "   First 5 lines of Dockerfile:"
  head -5 Dockerfile
else
  echo "   NO - Dockerfile NOT in current directory"
fi

echo ""
echo "3. SEARCHING FOR DOCKERFILE:"
echo "   Looking for Dockerfile in common locations..."
for dir in . ${GITHUB_WORKSPACE} /__w /__w/workflow-tests /__w/workflow-tests/workflow-tests /github/workspace /home/runner/work; do
  if [ -d "$dir" ]; then
    echo "   Checking $dir:"
    if [ -f "$dir/Dockerfile" ]; then
      echo "   ✓ FOUND at $dir/Dockerfile"
    else
      echo "   ✗ Not found"
      echo "     Contents of $dir:"
      ls -la "$dir" 2>/dev/null | head -5 || echo "     Cannot list directory"
    fi
  else
    echo "   Directory $dir does not exist"
  fi
done

echo ""
echo "4. FIND ALL DOCKERFILES:"
echo "   Using find to locate any Dockerfile in filesystem:"
find / -name "Dockerfile" -type f 2>/dev/null | head -10 || echo "   No Dockerfiles found or permission denied"

echo ""
echo "5. BUILDAH CONFIGURATION:"
echo "   Buildah version: $(buildah --version)"
echo "   Storage driver: ${STORAGE_DRIVER:-not set}"
echo "   Buildah isolation: ${BUILDAH_ISOLATION:-not set}"
echo "   Checking buildah storage:"
buildah info 2>&1 | head -20

echo ""
echo "6. PROCESS INFO:"
echo "   Process tree:"
ps auxf | head -20

echo ""
echo "7. MOUNT INFORMATION:"
echo "   Current mounts:"
mount | grep -E "(overlay|/__w|workspace)" || echo "   No relevant mounts found"

echo ""
echo "8. ATTEMPTING BUILD WITH EXPLICIT PATHS:"

# Let's try to find where the Dockerfile really is
DOCKERFILE_LOCATION=""
for location in "./Dockerfile" "${GITHUB_WORKSPACE}/Dockerfile" "/__w/workflow-tests/workflow-tests/Dockerfile"; do
  if [ -f "$location" ]; then
    DOCKERFILE_LOCATION="$location"
    echo "   Found Dockerfile at: $DOCKERFILE_LOCATION"
    break
  fi
done

if [ -z "$DOCKERFILE_LOCATION" ]; then
  echo "   ERROR: Could not find Dockerfile anywhere!"
  echo "   Trying one more thing - listing everything under /__w:"
  find /__w -type f -name "*" 2>/dev/null | head -20 || echo "   /__w not accessible"
  echo ""
  echo "   And everything in current directory recursively:"
  find . -type f 2>/dev/null | head -20
  exit 1
fi

# Try to get the directory containing the Dockerfile
BUILD_CONTEXT_DIR=$(dirname "$DOCKERFILE_LOCATION")
echo "   Using build context: $BUILD_CONTEXT_DIR"
echo "   Contents of build context directory:"
ls -la "$BUILD_CONTEXT_DIR" | head -10

echo ""
echo "9. ATTEMPTING BUILD:"
echo "   Running: buildah bud -f $DOCKERFILE_LOCATION $BUILD_CONTEXT_DIR"

SHORT_SHA=$(echo "${IMAGE_TAG:-${GITHUB_SHA}}" | cut -c1-7)
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

# Build target argument
TARGET_ARG=""
if [ -n "${BUILD_TARGET}" ]; then
  TARGET_ARG="--target ${BUILD_TARGET}"
fi

# Prepare tags - always include latest and short SHA
TAGS="-t ${REGISTRY}/${IMAGE_NAME}:latest -t ${REGISTRY}/${IMAGE_NAME}:${SHORT_SHA}"

# Add custom tag if provided
if [ -n "${CUSTOM_TAG}" ]; then
  echo "   Adding custom tag: ${CUSTOM_TAG}"
  TAGS="${TAGS} -t ${REGISTRY}/${IMAGE_NAME}:${CUSTOM_TAG}"
else
  echo "   No custom tag provided, using default tags only"
fi

echo "   Tags to be created:"
echo "     - ${REGISTRY}/${IMAGE_NAME}:latest"
echo "     - ${REGISTRY}/${IMAGE_NAME}:${SHORT_SHA}"
if [ -n "${CUSTOM_TAG}" ]; then
  echo "     - ${REGISTRY}/${IMAGE_NAME}:${CUSTOM_TAG}"
fi

# Try the build with maximum verbosity
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
  "$BUILD_CONTEXT_DIR" 2>&1

BUILD_EXIT_CODE=$?
echo ""
echo "Build exit code: $BUILD_EXIT_CODE"

if [ $BUILD_EXIT_CODE -eq 125 ]; then
  echo "Exit code 125 means buildah runtime failure - usually can't find Dockerfile or context"
fi

exit $BUILD_EXIT_CODE
