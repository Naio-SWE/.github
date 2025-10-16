#!/bin/bash
set -e

echo "Configuring Buildah storage and registries..."

mkdir -p /var/lib/containers/storage
mkdir -p ~/.config/containers

# Configure storage
cat >~/.config/containers/storage.conf <<EOF
[storage]
driver = "vfs"
graphroot = "/var/lib/containers/storage"
runroot = "/var/run/containers/storage"
EOF

# Configure registries - use docker.io as default
cat >~/.config/containers/registries.conf <<EOF
unqualified-search-registries = ["docker.io"]

[[registry]]
location = "docker.io"
EOF

echo "✓ Storage and registries configured"
