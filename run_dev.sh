#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cleanup() {
    echo ""
    echo "Shutting down servers..."
    kill $SERVER_PID 2>/dev/null || true
    kill $FRONTEND_PID 2>/dev/null || true
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

# Kill any existing instances by port (more reliable)
echo "Cleaning up old processes..."
lsof -ti :3000 | xargs kill -9 2>/dev/null || true
lsof -ti :8080 | xargs kill -9 2>/dev/null || true
sleep 2

echo "==================================="
echo "  TaskFlow Development Environment"
echo "==================================="
echo ""

# Step 1: Get dependencies for build tool
echo "[1/7] Setting up build tool..."
cd "$SCRIPT_DIR/tools/build"
dart pub get

# Step 2: Get dependencies for all packages
echo ""
echo "[2/7] Getting dependencies for all packages..."
for pkg in "$SCRIPT_DIR/packages"/*; do
    [ -f "$pkg/pubspec.yaml" ] && (cd "$pkg" && echo "  $(basename "$pkg")..." && dart pub get)
done

# Step 3: Get dependencies for all examples (Dart)
echo ""
echo "[3/7] Getting dependencies for all examples..."
for example in "$SCRIPT_DIR/examples"/*; do
    [ -f "$example/pubspec.yaml" ] && (cd "$example" && echo "  $(basename "$example")..." && dart pub get)
done

# Step 4: npm install for backend
echo ""
echo "[4/7] Installing Node dependencies for backend..."
cd "$SCRIPT_DIR/examples/backend"
[ -d "node_modules" ] || npm install

# Step 5: npm install for mobile/rn (Expo)
echo ""
echo "[5/7] Installing Node dependencies for mobile (Expo)..."
cd "$SCRIPT_DIR/examples/mobile/rn"
[ -d "node_modules" ] || npm install

# Step 6: Build all targets
echo ""
echo "[6/7] Building all targets..."
cd "$SCRIPT_DIR"

# Build backend
echo "  Building backend..."
dart run tools/build/build.dart backend

# Build mobile
echo "  Building mobile..."
dart run tools/build/build.dart mobile

# Build frontend (browser JS, not node preamble)
echo "  Building frontend..."
cd "$SCRIPT_DIR/examples/frontend"
mkdir -p build
dart compile js web/app.dart -o build/app.js -O2

# Step 7: Start servers
echo ""
echo "[7/7] Starting servers..."
echo ""

# Start Express backend on port 3000
cd "$SCRIPT_DIR/examples/backend"
node build/server.js &
SERVER_PID=$!

# Start simple HTTP server for frontend on port 8080
cd "$SCRIPT_DIR/examples/frontend"
python3 -m http.server 8080 &
FRONTEND_PID=$!

sleep 2

echo "==================================="
echo "  Servers running!"
echo "==================================="
echo ""
echo "  Backend API:  http://localhost:3000"
echo "  Frontend:     http://localhost:8080/web/"
echo ""
echo "  Mobile: Use VSCode launch config or run:"
echo "    cd examples/mobile/rn && npm run ios"
echo "    cd examples/mobile/rn && npm run android"
echo ""
echo "  Press Ctrl+C to stop"
echo "==================================="
echo ""

wait $SERVER_PID $FRONTEND_PID
