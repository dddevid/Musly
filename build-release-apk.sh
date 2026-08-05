#!/usr/bin/env bash
# Build a release APK using Docker (data stored in /rw/docker).
# Usage:  ./build-release-apk.sh [output-dir]
# The APK is copied to <output-dir> (default: ./release-apk)
set -euo pipefail

OUTPUT_DIR="${1:-$(pwd)/release-apk}"
IMAGE_TAG="musly-release-builder"
CONTAINER_NAME="musly-apk-build"

cd "$(dirname "$0")"

echo "==> Building Docker image: $IMAGE_TAG"
sudo docker build -f Dockerfile.release -t "$IMAGE_TAG" .

echo "==> Extracting APK from image"
sudo docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
sudo docker create --name "$CONTAINER_NAME" "$IMAGE_TAG" echo done
mkdir -p "$OUTPUT_DIR"
sudo docker cp \
    "$CONTAINER_NAME:/app/build/app/outputs/flutter-apk/app-release.apk" \
    "$OUTPUT_DIR/musly-release.apk"
sudo docker rm -f "$CONTAINER_NAME"

echo ""
echo "==> APK ready: $OUTPUT_DIR/musly-release.apk"
ls -lh "$OUTPUT_DIR/musly-release.apk"
