#!/bin/bash
set -e

echo "Configuring Buildah storage..."

mkdir -p /var/lib/containers/storage
mkdir -p ~/.config/containers

cat >~/.config/containers/storage.conf <<EOF
[storage]
driver = "vfs"
graphroot = "/var/lib/containers/storage"
runroot = "/var/run/containers/storage"
EOF

echo "✓ Storage configured with VFS driver"
