#!/bin/bash
# VSCode extension operations: clean, build, install, uninstall
set -e
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPTS/.." && pwd)"
VSIX_DIR="$ROOT/too_many_cooks_vscode_extension"

usage() {
  echo "Usage: $0 {clean|build|install|uninstall}"
  exit 1
}

cmd_clean() {
  rm -rf "$VSIX_DIR"/*.vsix
  rm -rf "$VSIX_DIR/out"
  echo "VSIX build cleaned."
}

cmd_build() {
  echo "Building VSCode extension..."
  cd "$VSIX_DIR"
  npm install
  npm run compile
  npx @vscode/vsce package
  echo "VSCode extension built."
}

cmd_install() {
  cd "$VSIX_DIR"
  VSIX=$(ls -t *.vsix 2>/dev/null | head -1)

  if [ -z "$VSIX" ]; then
    echo "Error: No .vsix file found. Run '$0 build' first."
    exit 1
  fi

  code --install-extension "$VSIX" --force
  echo "VSCode extension installed: $VSIX"
  echo "Restart VSCode to activate."
}

cmd_uninstall() {
  code --uninstall-extension christianfindlay.too-many-cooks 2>/dev/null || true
  echo "VSCode extension uninstalled."
}

case "${1:-}" in
  clean)      cmd_clean ;;
  build)      cmd_build ;;
  install)    cmd_install ;;
  uninstall)  cmd_uninstall ;;
  *)          usage ;;
esac
