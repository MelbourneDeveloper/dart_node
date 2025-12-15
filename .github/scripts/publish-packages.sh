#!/bin/bash
# Publishes packages to pub.dev
# Usage: publish-packages.sh <version> <packages...>

set -e

VERSION="$1"
shift
PACKAGES="$@"

for pkg in $PACKAGES; do
  echo "::group::Publishing $pkg"

  # Check if version already exists on pub.dev
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://pub.dev/api/packages/$pkg/versions/$VERSION")
  if [ "$HTTP_CODE" = "200" ]; then
    echo "⏭ $pkg $VERSION already published, skipping"
    echo "::endgroup::"
    continue
  fi

  cd packages/$pkg
  dart pub get
  dart pub publish --force
  cd ../..
  echo "::endgroup::"
done
