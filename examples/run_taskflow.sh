#!/bin/bash
# Build and run the TaskFlow demo (Express + React + React Native)
# Dependencies are installed by .devcontainer/post-create.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cleanup() {
    echo ""
    echo "Shutting down servers..."
    kill $SERVER_PID 2>/dev/null || true
    kill $FRONTEND_PID 2>/dev/null || true
    exit 0
}

trap cleanup INT TERM EXIT

# Kill any existing instances by port
echo "Cleaning up old processes..."
lsof -ti :3000 | xargs kill -9 2>/dev/null || true
lsof -ti :8080 | xargs kill -9 2>/dev/null || true
sleep 2

echo "==================================="
echo "  TaskFlow Development Environment"
echo "==================================="
echo ""

# Step 1: Build all targets
echo "[1/2] Building all targets..."
cd "$ROOT_DIR"

echo "  Building backend..."
dart run tools/build/build.dart backend

echo "  Building mobile..."
dart run tools/build/build.dart mobile

echo "  Building frontend..."
cd "$SCRIPT_DIR/frontend"
mkdir -p build
dart compile js web/app.dart -o build/app.js -O2

# Step 2: Start servers
echo ""
echo "[2/2] Starting servers..."
echo ""

cd "$SCRIPT_DIR/backend"
node build/server.js &
SERVER_PID=$!

cd "$SCRIPT_DIR/frontend"
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
