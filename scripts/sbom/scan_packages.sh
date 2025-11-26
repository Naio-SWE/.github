#!/bin/bash
set -e

SYFT_PATH="${1:-$HOME/.local/bin/syft}"

echo "=== Scanning Packages ==="

mkdir -p sboms

# Scan Python
if [ -s /tmp/python-packages.txt ]; then
  echo "Scanning Python virtual environment..."
  source venv/bin/activate
  $SYFT_PATH scan "dir:./venv" -o cyclonedx-json=/tmp/python-sbom.json
else
  echo "No Python packages to scan"
fi

# Scan JavaScript
for node_modules in $(find . -name "node_modules" -type d -not -path "*/node_modules/node_modules" | head -10); do
  echo "Scanning JavaScript from $node_modules"
  HASH=$(echo "$node_modules" | md5sum | cut -d' ' -f1)
  $SYFT_PATH scan "dir:$node_modules" -o cyclonedx-json=/tmp/js-sbom-${HASH}.json
done

echo "=== Scanning complete ==="
