#!/bin/bash
set -e

cd "$(dirname "$0")/.."

node scripts/copy-readmes.js
bash scripts/generate-api-docs.sh
npx eleventy
