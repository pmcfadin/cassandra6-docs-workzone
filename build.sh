#!/usr/bin/env bash
# build.sh — Cassandra 6 Docs Workzone build wrapper
# Usage:
#   ./build.sh build     Build the Antora site
#   ./build.sh preview   Start a local preview server
#   ./build.sh clean     Remove build artifacts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYBOOK="$SCRIPT_DIR/antora-playbook.yml"
BUILD_DIR="$SCRIPT_DIR/build/site"

# ── Dependency checks ──────────────────────────────────────────────

check_node() {
  if ! command -v node &>/dev/null; then
    echo "ERROR: Node.js is required but not found." >&2
    echo "Install Node.js 16+ from https://nodejs.org/" >&2
    exit 1
  fi
}

check_npx() {
  if ! command -v npx &>/dev/null; then
    echo "ERROR: npx is required but not found (ships with Node.js)." >&2
    exit 1
  fi
}

# ── Commands ───────────────────────────────────────────────────────

cmd_build() {
  check_node
  check_npx
  echo "Building Antora site..."
  npx antora "$PLAYBOOK"
  # Bypass Jekyll on GitHub Pages
  touch "$BUILD_DIR/.nojekyll"
  echo "Build complete → $BUILD_DIR"
}

cmd_preview() {
  if [ ! -d "$BUILD_DIR" ]; then
    echo "No build output found. Run './build.sh build' first." >&2
    exit 1
  fi
  check_node
  echo "Starting preview server at http://localhost:5151"
  echo "Press Ctrl-C to stop."
  npx http-server "$BUILD_DIR" -p 5151 -c-1
}

cmd_clean() {
  echo "Removing build artifacts..."
  rm -rf "$SCRIPT_DIR/build"
  echo "Clean complete."
}

# ── Main ───────────────────────────────────────────────────────────

case "${1:-}" in
  build)   cmd_build ;;
  preview) cmd_preview ;;
  clean)   cmd_clean ;;
  *)
    echo "Usage: $0 {build|preview|clean}" >&2
    exit 1
    ;;
esac
