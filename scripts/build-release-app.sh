#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="$ROOT_DIR/.xcode-derived-release"
OUTPUT_DIR="$ROOT_DIR/release"
APP_NAME="Static Menu Publisher.app"
SOURCE_APP="$DERIVED_DATA/Build/Products/Release/$APP_NAME"
TARGET_APP="$OUTPUT_DIR/$APP_NAME"

mkdir -p "$OUTPUT_DIR"

xcodebuild \
  -project "$ROOT_DIR/MyataStaticMenuSwift.xcodeproj" \
  -scheme MyataStaticMenuSwift \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  build

rm -rf "$TARGET_APP"
cp -R "$SOURCE_APP" "$TARGET_APP"

echo "Built release app:"
echo "$TARGET_APP"
