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

# Build Express server
echo "[1/4] Building Express server..."
cd "$SCRIPT_DIR/tools/build"
dart pub get
cd "$SCRIPT_DIR"
dart run tools/build/build.dart backend

# Install Node dependencies if needed
echo ""
echo "[2/4] Checking Node dependencies..."
cd "$SCRIPT_DIR/examples/backend"
[ -d "node_modules" ] || npm install

# Build React app
echo ""
echo "[3/4] Building React app..."
cd "$SCRIPT_DIR/examples/frontend"
dart pub get
dart compile js web/app.dart -o build/app.js -O2

# Start servers
echo ""
echo "[4/4] Starting servers..."
echo ""

# Start Express backend on port 3000
cd "$SCRIPT_DIR/examples/backend"
node build/server.js &
SERVER_PID=$!

# Start simple HTTP server for frontend on port 8080
# Serve from frontend root so both web/ and build/ are accessible
cd "$SCRIPT_DIR/examples/frontend"
python3 -m http.server 8080 &
FRONTEND_PID=$!

sleep 1

echo "==================================="
echo "  Servers running!"
echo "==================================="
echo ""
echo "  Backend API:  http://localhost:3000"
echo "  Frontend:     http://localhost:8080/web/"
echo ""
echo "  Press Ctrl+C to stop"
echo "==================================="
echo ""

wait $SERVER_PID $FRONTEND_PID
