#!/bin/bash
set -e

REPO="nebulity/latdx-cli"
BINARY_NAME="latdx"
INSTALL_DIR="${LATDX_INSTALL_DIR:-$HOME/.local/bin}"

# Parse command line arguments
VERSION="$1"  # Optional: specific version (e.g., 0.15.2)

if [[ -n "$VERSION" ]] && [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Usage: $0 [VERSION]" >&2
    echo "  VERSION: semantic version (e.g., 0.15.2). Defaults to latest." >&2
    exit 1
fi

# Check for curl or wget
DOWNLOADER=""
if command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget"
else
    echo "Error: curl or wget is required" >&2
    exit 1
fi

download() {
    local url="$1" output="$2"
    if [ "$DOWNLOADER" = "curl" ]; then
        if [ -n "$output" ]; then curl -fsSL -o "$output" "$url"
        else curl -fsSL "$url"; fi
    else
        if [ -n "$output" ]; then wget -q -O "$output" "$url"
        else wget -q -O - "$url"; fi
    fi
}

# Detect OS
case "$(uname -s)" in
    Darwin) os="darwin" ;;
    Linux)  os="linux" ;;
    MINGW*|MSYS*|CYGWIN*) os="win" ;;
    *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

# Detect architecture
case "$(uname -m)" in
    x86_64|amd64) arch="x64" ;;
    arm64|aarch64) arch="arm64" ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

# Rosetta 2 detection: prefer native arm64 on Apple Silicon
if [ "$os" = "darwin" ] && [ "$arch" = "x64" ]; then
    if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" = "1" ]; then
        arch="arm64"
    fi
fi

# Build asset name
if [ "$os" = "win" ]; then
    asset_name="${BINARY_NAME}-${os}-${arch}.exe"
else
    asset_name="${BINARY_NAME}-${os}-${arch}"
fi

echo "Detected platform: ${os}-${arch}"

# Resolve version
if [ -z "$VERSION" ]; then
    echo "Fetching latest release..."
    VERSION=$(download "https://api.github.com/repos/${REPO}/releases/latest" "" | \
        grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "cli-v\([^"]*\)".*/\1/')
    if [ -z "$VERSION" ]; then
        echo "Error: could not determine latest version" >&2
        exit 1
    fi
fi

RELEASE_TAG="cli-v${VERSION}"
BASE_URL="https://github.com/${REPO}/releases/download/${RELEASE_TAG}"

echo "Installing ${BINARY_NAME} v${VERSION}..."

# Create temp directory
TMPDIR_INSTALL="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_INSTALL"' EXIT

# Download binary and checksums
echo "Downloading ${asset_name}..."
download "${BASE_URL}/${asset_name}" "${TMPDIR_INSTALL}/${asset_name}"
download "${BASE_URL}/SHA256SUMS" "${TMPDIR_INSTALL}/SHA256SUMS"

# Verify checksum
echo "Verifying checksum..."
expected=$(grep "${asset_name}" "${TMPDIR_INSTALL}/SHA256SUMS" | awk '{print $1}')
if [ -z "$expected" ]; then
    echo "Error: ${asset_name} not found in SHA256SUMS" >&2
    exit 1
fi

if [ "$os" = "darwin" ]; then
    actual=$(shasum -a 256 "${TMPDIR_INSTALL}/${asset_name}" | awk '{print $1}')
else
    actual=$(sha256sum "${TMPDIR_INSTALL}/${asset_name}" | awk '{print $1}')
fi

if [ "$actual" != "$expected" ]; then
    echo "Error: checksum mismatch" >&2
    echo "  expected: ${expected}" >&2
    echo "  actual:   ${actual}" >&2
    exit 1
fi

echo "Checksum verified."

# Optional: verify minisign signature
if command -v minisign >/dev/null 2>&1; then
    if download "${BASE_URL}/SHA256SUMS.minisig" "${TMPDIR_INSTALL}/SHA256SUMS.minisig" 2>/dev/null; then
        PUBKEY="RWRg/erd72b5rVMgbjzeb+02CkOVWtkN+kCduGAEUKES/2QkXYgaPZ0Q"
        if minisign -Vm "${TMPDIR_INSTALL}/SHA256SUMS" -P "$PUBKEY" -q 2>/dev/null; then
            echo "Signature verified."
        else
            echo "Warning: signature verification failed" >&2
        fi
    fi
fi

# Install
mkdir -p "$INSTALL_DIR"
cp "${TMPDIR_INSTALL}/${asset_name}" "${INSTALL_DIR}/${BINARY_NAME}"
chmod +x "${INSTALL_DIR}/${BINARY_NAME}"

echo ""
echo "Installed ${BINARY_NAME} v${VERSION} to ${INSTALL_DIR}/${BINARY_NAME}"

# Check if INSTALL_DIR is in PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
    echo ""
    echo "Add ${INSTALL_DIR} to your PATH:"
    shell_name="$(basename "$SHELL")"
    case "$shell_name" in
        zsh)  rc="~/.zshrc" ;;
        bash) rc="~/.bashrc" ;;
        fish) echo "  fish_add_path ${INSTALL_DIR}"; exit 0 ;;
        *)    rc="your shell config" ;;
    esac
    echo "  echo 'export PATH=\"${INSTALL_DIR}:\$PATH\"' >> ${rc}"
    echo "  source ${rc}"
    echo ""
fi

echo "Run '${BINARY_NAME} --help' to get started."
