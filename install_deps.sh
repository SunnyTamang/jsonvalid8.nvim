#!/bin/sh

# jsonvalid8.nvim dependency installer
# This script installs Python 3, pip, and the jsonschema library.

set -e

# Check for Python 3
if ! command -v python3 >/dev/null 2>&1; then
  echo "[jsonvalid8.nvim] Python 3 is not installed. Please install Python 3 and re-run this script."
  exit 1
fi

# Check for pip
if ! command -v pip3 >/dev/null 2>&1; then
  echo "[jsonvalid8.nvim] pip3 is not installed. Attempting to install pip..."
  python3 -m ensurepip --upgrade || {
    echo "[jsonvalid8.nvim] Failed to install pip. Please install pip manually."; exit 1;
  }
fi

# Install jsonschema
echo "[jsonvalid8.nvim] Installing Python jsonschema library..."
pip3 install --user --upgrade jsonschema

echo "[jsonvalid8.nvim] All dependencies installed successfully!" 