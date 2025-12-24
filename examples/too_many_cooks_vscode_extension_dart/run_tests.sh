#!/bin/bash
set -e
cd "$(dirname "$0")/../too_many_cooks"
dart compile js -o build/bin/server.js bin/server.dart
cd ../..
dart run tools/build/add_preamble.dart examples/too_many_cooks/build/bin/server.js examples/too_many_cooks/build/bin/server_node.js
cd examples/too_many_cooks_vscode_extension_dart
dart test
