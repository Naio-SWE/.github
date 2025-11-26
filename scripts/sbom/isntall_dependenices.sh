#!/bin/bash
set -e

INTERNAL_PACKAGE_PATTERN="${1:-yasp\\.}"

echo "=== Installing Python Dependencies ==="

if find . -name "requirements*.txt" -type f | grep -q .; then
  echo "Found Python requirements files"

  python -m venv venv
  source venv/bin/activate
  pip install -q --upgrade pip

  # Combine and filter requirements
  find . -name "requirements*.txt" -exec cat {} \; |
    grep -v "^#" |
    grep -v "^$" |
    grep -v "$INTERNAL_PACKAGE_PATTERN" |
    sort -u >/tmp/filtered-requirements.txt

  echo "Installing packages..."
  pip install -r /tmp/filtered-requirements.txt || true

  pip install pip-licenses
  pip freeze >/tmp/python-packages.txt

  echo "Extracting Python license information..."
  pip-licenses --format=json --with-authors --with-urls >/tmp/python-licenses.json
else
  echo "No Python requirements found"
  touch /tmp/python-packages.txt
  echo "[]" >/tmp/python-licenses.json
fi

echo ""
echo "=== Installing JavaScript Dependencies ==="

if find . -name "package.json" -type f -not -path "*/node_modules/*" | grep -q .; then
  echo "Found JavaScript package.json files"

  for pkg in $(find . -name "package.json" -not -path "*/node_modules/*"); do
    dir=$(dirname "$pkg")
    echo "Installing from $dir"
    cd "$dir"
    npm install || true
    cd -
  done

  echo "Extracting JavaScript license information..."
  echo "{}" >/tmp/js-licenses-combined.json

  for pkg in $(find . -name "package.json" -not -path "*/node_modules/*"); do
    dir=$(dirname "$pkg")
    if [ -d "$dir/node_modules" ]; then
      echo "Scanning licenses in $dir"
      cd "$dir"
      npx license-checker --json >/tmp/js-licenses-$(basename $dir).json 2>/dev/null || echo "{}" >/tmp/js-licenses-$(basename $dir).json
      cd -
    fi
  done
else
  echo "No JavaScript dependencies found"
fi

echo ""
echo "=== Dependencies installed ==="
