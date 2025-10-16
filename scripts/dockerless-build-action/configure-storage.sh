#!/bin/bash
set -e

echo "Configuring Buildah storage..."
mkdir -p /var/lib/containers/storage
mkdir -p ~/.config/containers
mkdir -p /etc/containers/registries.conf.d

# Storage configuration
cat >~/.config/containers/storage.conf <<EOF
[storage]
driver = "overlay"
graphroot = "/var/lib/containers/storage"
runroot = "/var/run/containers/storage"
[storage.options]
mount_program = "/usr/bin/fuse-overlayfs"
EOF

# Registry configuration for short-name resolution
cat >/etc/containers/registries.conf.d/001-dockerio.conf <<EOF
unqualified-search-registries = ["docker.io"]

[[registry]]
location = "docker.io"
insecure = false

# Short-name alias for pytorch images
[aliases]
"pytorch/pytorch" = "docker.io/pytorch/pytorch"
EOF

# Alternative: Just set docker.io as default for all unqualified images
cat >/etc/containers/registries.conf <<EOF
[registries.search]
registries = ['docker.io']

[registries.insecure]
registries = []

[registries.block]
registries = []

unqualified-search-registries = ["docker.io"]
EOF

echo "✓ Storage configured with overlay driver"
echo "✓ Registry configured with docker.io as default"
