#!/bin/bash
# Generic script to update the main package version in a PyPI formula
# This only updates the main package URL and SHA256, NOT the dependencies
set -e

FORMULA_NAME="$1"
VERSION="$2"

if [ -z "$FORMULA_NAME" ] || [ -z "$VERSION" ]; then
    echo "Usage: $0 <formula-name> <version>"
    echo "Example: $0 nextdns-blocker 5.4.0"
    exit 1
fi

# Convert formula name to PyPI package name (replace - with _)
PYPI_NAME="${FORMULA_NAME//-/_}"

echo "Updating $FORMULA_NAME formula to version $VERSION"

# Get the tarball URL and SHA256 from PyPI JSON API
echo "Fetching package info from PyPI..."
PYPI_JSON=$(curl -sL "https://pypi.org/pypi/${FORMULA_NAME}/${VERSION}/json")

if [ -z "$PYPI_JSON" ] || [ "$PYPI_JSON" = "null" ]; then
    echo "Error: Could not fetch package info from PyPI"
    exit 1
fi

# Extract URL and SHA256 for the sdist (source tarball)
TARBALL_URL=$(echo "$PYPI_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); urls=[u for u in d['urls'] if u['packagetype']=='sdist']; print(urls[0]['url'] if urls else '')")
SHA256=$(echo "$PYPI_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); urls=[u for u in d['urls'] if u['packagetype']=='sdist']; print(urls[0]['digests']['sha256'] if urls else '')")

if [ -z "$TARBALL_URL" ] || [ -z "$SHA256" ]; then
    echo "Error: Could not find source tarball for $FORMULA_NAME $VERSION"
    exit 1
fi

echo "URL: $TARBALL_URL"
echo "SHA256: $SHA256"

# Update the formula - only the main package (lines before first 'resource' block)
FORMULA_PATH="Formula/${FORMULA_NAME}.rb"

if [ ! -f "$FORMULA_PATH" ]; then
    echo "Error: Formula not found at $FORMULA_PATH"
    exit 1
fi

# Use Python to update only the main package URL and SHA256
python3 << EOF
import re

with open("$FORMULA_PATH", "r") as f:
    content = f.read()

# Find the position of the first 'resource' block
resource_pos = content.find('resource "')
if resource_pos == -1:
    resource_pos = len(content)

# Split content into main section and resources
main_section = content[:resource_pos]
resources_section = content[resource_pos:]

# Update URL in main section only (matches url "https://..." pattern)
main_section = re.sub(
    r'url "https://[^"]+"',
    'url "$TARBALL_URL"',
    main_section,
    count=1
)

# Update SHA256 in main section only (first occurrence)
main_section = re.sub(
    r'sha256 "[a-f0-9]+"',
    'sha256 "$SHA256"',
    main_section,
    count=1
)

# Combine and write back
with open("$FORMULA_PATH", "w") as f:
    f.write(main_section + resources_section)

print("Formula updated successfully!")
EOF

echo ""
echo "Formula updated:"
echo "  Formula: $FORMULA_PATH"
echo "  Version: $VERSION"
echo "  URL: $TARBALL_URL"
echo "  SHA256: $SHA256"
