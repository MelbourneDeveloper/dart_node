#!/bin/bash
set -e

cd "$(dirname "$0")/.."

bash scripts/clean.sh
npm install
bash scripts/build.sh
