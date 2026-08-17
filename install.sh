#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://packages.7net.vn"
KEY_URL="${REPO_URL}/7net-archive-keyring.asc"
KEY_FILE="/etc/apt/keyrings/7net.asc"
SOURCE_FILE="/etc/apt/sources.list.d/7net.sources"

PACKAGE="${1:-7net-recorder}"

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: Please run this installer with sudo."
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "Error: This installer requires an APT-based Linux distribution."
    exit 1
fi

ARCH="$(dpkg --print-architecture)"

if [ "$ARCH" != "amd64" ]; then
    echo "Error: 7net packages currently support amd64 only."
    echo "Detected architecture: $ARCH"
    exit 1
fi

echo "==> Installing $PACKAGE"
echo "==> Configuring 7net APT repository..."

install -d -m 0755 /etc/apt/keyrings

TMP_KEY="$(mktemp)"
trap 'rm -f "$TMP_KEY"' EXIT

curl -fsSL "$KEY_URL" -o "$TMP_KEY"
install -m 0644 "$TMP_KEY" "$KEY_FILE"

cat > "$SOURCE_FILE" <<SOURCE
Types: deb
URIs: ${REPO_URL}/
Suites: stable
Components: main
Architectures: amd64
Signed-By: ${KEY_FILE}
SOURCE

# Remove old Recorder-specific configuration if it exists.
rm -f /etc/apt/sources.list.d/7net-recorder.sources
rm -f /etc/apt/keyrings/7net-recorder.asc

echo "==> Updating package index..."
apt-get update

echo "==> Installing $PACKAGE..."
apt-get install -y -- "$PACKAGE"

echo
echo "========================================"
echo " $PACKAGE installed successfully."
echo "========================================"
