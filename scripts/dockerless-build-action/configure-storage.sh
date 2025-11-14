#!/bin/bash
set -e
#configure-storage.sh
echo "Configuring Buildah storage..."

mkdir -p /var/lib/containers/storage
mkdir -p ~/.config/containers
mkdir -p /etc/containers/registries.conf.d

cat >~/.config/containers/storage.conf <<EOF
[storage]
driver = "overlay"
graphroot = "/var/lib/containers/storage"
runroot = "/var/run/containers/storage"
[storage.options]
mount_program = "/usr/bin/fuse-overlayfs"
EOF

cat >/etc/containers/registries.conf.d/001-dockerio.conf <<EOF
unqualified-search-registries = ["docker.io"]
[[registry]]
location = "docker.io"
insecure = false
[aliases]
"pytorch/pytorch" = "docker.io/pytorch/pytorch"
EOF

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

echo ""
echo "Checking for cached images:"
buildah images 2>/dev/null || echo "No cached images yet"
echo ""
echo "Storage disk usage:"
df -h /var/lib/containers 2>/dev/null || true
