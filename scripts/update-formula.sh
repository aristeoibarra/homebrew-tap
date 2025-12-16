#!/bin/bash
set -e

VERSION="$1"

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

echo "Updating nextdns-blocker formula to version $VERSION"

# Download the source tarball and calculate SHA256
TARBALL_URL="https://files.pythonhosted.org/packages/source/n/nextdns-blocker/nextdns_blocker-${VERSION}.tar.gz"
echo "Downloading $TARBALL_URL"

TEMP_DIR=$(mktemp -d)
curl -sL "$TARBALL_URL" -o "$TEMP_DIR/nextdns_blocker-${VERSION}.tar.gz"
SHA256=$(shasum -a 256 "$TEMP_DIR/nextdns_blocker-${VERSION}.tar.gz" | awk '{print $1}')
echo "SHA256: $SHA256"

# Update the formula
FORMULA_PATH="Formula/nextdns-blocker.rb"

# Update version URL
sed -i.bak "s|url \"https://files.pythonhosted.org/packages/source/n/nextdns-blocker/nextdns_blocker-.*\.tar\.gz\"|url \"https://files.pythonhosted.org/packages/source/n/nextdns-blocker/nextdns_blocker-${VERSION}.tar.gz\"|" "$FORMULA_PATH"

# Update SHA256
sed -i.bak "s|sha256 \"[a-f0-9]*\"|sha256 \"${SHA256}\"|" "$FORMULA_PATH"

# Clean up backup files
rm -f "$FORMULA_PATH.bak"
rm -rf "$TEMP_DIR"

echo "Formula updated successfully!"
echo "New URL: $TARBALL_URL"
echo "New SHA256: $SHA256"
