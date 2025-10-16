#!/bin/bash
set -e

echo "Configuring Buildah storage..."

mkdir -p /var/lib/containers/storage
mkdir -p ~/.config/containers

cat >~/.config/containers/storage.conf <<EOF
[storage]
driver = "overlay"
graphroot = "/var/lib/containers/storage"
runroot = "/var/run/containers/storage"

[storage.options]
mount_program = "/usr/bin/fuse-overlayfs"
EOF

echo "✓ Storage configured with overlay driver"
