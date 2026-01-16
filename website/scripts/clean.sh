#!/bin/bash
set -e

cd "$(dirname "$0")/.."

rm -rf _site
rm -rf node_modules
rm -rf .dart-doc-temp
rm -rf src/docs/*/index.md
rm -rf src/api
