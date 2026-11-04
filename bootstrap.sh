#!/usr/bin/env bash
set -Eeuo pipefail

# Replace this URL with your public GitHub repository.
REPO_TARBALL="https://github.com/epiiccccc/chromesetup/archive/refs/heads/tar.gz"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

command -v curl >/dev/null 2>&1 || {
  echo "curl ontbreekt. Installeer eerst curl."
  exit 1
}
command -v tar >/dev/null 2>&1 || {
  echo "tar ontbreekt. Installeer eerst tar."
  exit 1
}

curl -fsSL "$REPO_TARBALL" | tar -xz -C "$TMP_DIR"
PROJECT_DIR="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
[[ -f "$PROJECT_DIR/install.sh" ]] || {
  echo "Kon install.sh niet vinden in de GitHub-download."
  exit 1
}
bash "$PROJECT_DIR/install.sh"
