#!/bin/bash
# Run VSCode extension tests
set -e
cd "$(dirname "$0")/../too_many_cooks_vscode_extension"

npm test
