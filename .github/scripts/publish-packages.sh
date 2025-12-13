#!/bin/bash
# Publishes packages to pub.dev
# Usage: publish-packages.sh <version> <packages...>

set -e

VERSION="$1"
shift
PACKAGES="$@"

for pkg in $PACKAGES; do
  echo "::group::Publishing $pkg"
  cd packages/$pkg
  dart pub get
  dart pub publish --force
  cd ../..
  echo "::endgroup::"
done
