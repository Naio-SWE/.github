#!/bin/bash
set -e

echo "========================================="
echo "Environment Information"
echo "========================================="
echo "Runner: $(uname -a)"
echo "Buildah version: $(buildah --version)"
echo "Working directory: $(pwd)"
echo "Registry: ${REGISTRY}"
echo "Image name: ${IMAGE_NAME}"
echo "Git commit: ${GITHUB_SHA}"
echo "Git ref: ${GITHUB_REF}"
echo "========================================="
