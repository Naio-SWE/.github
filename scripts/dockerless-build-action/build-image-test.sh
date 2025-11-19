#!/bin/bash

#build-image.sh
set -e

echo "========================================="
echo "DEBUG: Starting build-image.sh"
echo "========================================="

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

BUILD_CONTEXT_DIR=$(dirname "$DOCKERFILE_LOCATION")
echo "   Using build context: $BUILD_CONTEXT_DIR"
echo "   Contents of build context directory:"
ls -la "$BUILD_CONTEXT_DIR" | head -10

echo ""
echo "9. GIT STATE VERIFICATION (CRITICAL FOR SETUPTOOLS-SCM):"
cd "$BUILD_CONTEXT_DIR"

# Check if git is available
echo "   Git available?"
if command -v git &>/dev/null; then
  echo "   ✓ git is available: $(git --version)"
else
  echo "   ✗ ERROR: git NOT available - setuptools-scm will fail!"
  echo "   Installing git might be needed in your runner image"
fi

echo ""
echo "   .git directory exists?"
if [ -d ".git" ]; then
  echo "   ✓ .git directory exists at: $(pwd)/.git"
  echo "   .git directory size:"
  du -sh .git 2>/dev/null || echo "   Cannot calculate size"
  echo "   .git directory contents (top level):"
  ls -la .git | head -10
else
  echo "   ✗ ERROR: .git directory MISSING - setuptools-scm cannot work!"
  echo "   This means checkout didn't include git history"
  exit 1
fi

echo ""
echo "   Git repository status:"
git status --short 2>&1 || echo "   git status failed"

echo ""
echo "   Git configuration:"
git config --local --list | grep -E "(remote|branch)" || echo "   No remote/branch config"

echo ""
echo "   All git tags in repository:"
TAG_COUNT=$(git tag -l | wc -l)
echo "   Total tags: $TAG_COUNT"
if [ $TAG_COUNT -gt 0 ]; then
  echo "   Tags (showing first 20, sorted by version):"
  git tag -l | sort -V | head -20
else
  echo "   ⚠ WARNING: NO TAGS FOUND - setuptools-scm will generate dev versions!"
fi

echo ""
echo "   Git describe (what setuptools-scm sees):"
GIT_DESCRIBE=$(git describe --tags --long --dirty --always 2>&1)
echo "   $GIT_DESCRIBE"

echo ""
echo "   Latest tag (if any):"
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
if [ -n "$LATEST_TAG" ]; then
  echo "   ✓ Latest tag: $LATEST_TAG"
else
  echo "   ⚠ No tags found"
fi

echo ""
echo "   Current commit:"
CURRENT_COMMIT=$(git rev-parse HEAD 2>&1)
echo "   $CURRENT_COMMIT"

echo ""
echo "   Current branch:"
CURRENT_BRANCH=$(git branch --show-current 2>&1)
echo "   $CURRENT_BRANCH"

echo ""
echo "   GitHub context:"
echo "   GITHUB_REF: ${GITHUB_REF}"
echo "   GITHUB_REF_NAME: ${GITHUB_REF_NAME}"
echo "   GITHUB_SHA: ${GITHUB_SHA}"

if [[ "$GITHUB_REF" == refs/tags/* ]]; then
  EXPECTED_TAG="${GITHUB_REF_NAME}"
  echo ""
  echo "   ✓ Running on tag push: $EXPECTED_TAG"
  echo "   Verifying tag exists in repository..."
  if git tag -l | grep -q "^${EXPECTED_TAG}$"; then
    echo "   ✓✓ SUCCESS: Tag $EXPECTED_TAG is VISIBLE in build context!"
    echo "   setuptools-scm should use this tag for versioning"
  else
    echo "   ✗✗ ERROR: Tag $EXPECTED_TAG NOT FOUND in repository!"
    echo "   This will cause setuptools-scm to generate dev versions"
    echo "   Check if fetch-tags: true is set in checkout action"
    exit 1
  fi
else
  echo ""
  echo "   ⚠ NOT running on a tag (branch: ${GITHUB_REF_NAME})"
  echo "   setuptools-scm will generate a dev version (expected behavior)"
fi

echo ""
echo "   What version will setuptools-scm generate?"
if [ $TAG_COUNT -gt 0 ] && [ -n "$LATEST_TAG" ]; then
  COMMITS_SINCE=$(git rev-list ${LATEST_TAG}..HEAD --count 2>/dev/null || echo "?")
  if [ "$COMMITS_SINCE" = "0" ]; then
    echo "   ✓ On tagged commit: Version will be ${LATEST_TAG#v}"
  else
    echo "   ⚠ ${COMMITS_SINCE} commits after tag: Version will be ${LATEST_TAG#v}.dev${COMMITS_SINCE}+g${CURRENT_COMMIT:0:8}"
  fi
else
  echo "   ⚠ No tags: Version will be 0.0.0.dev0+g${CURRENT_COMMIT:0:8}"
fi

echo "========================================="

echo ""
echo "10. ATTEMPTING BUILD:"
echo "   Running: buildah bud -f $DOCKERFILE_LOCATION $BUILD_CONTEXT_DIR"

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
else
  echo "   No custom tag provided, using default tags only"
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
  "$BUILD_CONTEXT_DIR" 2>&1

BUILD_EXIT_CODE=$?
echo ""
echo "Build exit code: $BUILD_EXIT_CODE"

if [ $BUILD_EXIT_CODE -eq 125 ]; then
  echo "Exit code 125 means buildah runtime failure - usually can't find Dockerfile or context"
fi

exit $BUILD_EXIT_CODE
