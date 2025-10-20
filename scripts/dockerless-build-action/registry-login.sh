#!/bin/bash
set -e
#registry-login.sh
echo "Logging into ${REGISTRY}..."

if [ -z "${REGISTRY_USERNAME}" ] || [ -z "${REGISTRY_PASSWORD}" ]; then
  echo "❌ Error: REGISTRY_USERNAME or REGISTRY_PASSWORD not set"
  exit 1
fi

echo "${REGISTRY_PASSWORD}" | buildah login \
  --tls-verify=false \
  -u "${REGISTRY_USERNAME}" \
  --password-stdin \
  "${REGISTRY}"

echo "✓ Successfully logged in to ${REGISTRY}"
