#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="$ROOT_DIR/.xcode-derived-release"
OUTPUT_DIR="$ROOT_DIR/release"
APP_NAME="Static Menu Publisher.app"
SOURCE_APP="$DERIVED_DATA/Build/Products/Release/$APP_NAME"
TARGET_APP="$OUTPUT_DIR/$APP_NAME"
BUILD_NUMBER_FILE="$ROOT_DIR/Config/build-number.txt"
PROJECT_FILE="$ROOT_DIR/MyataStaticMenuSwift.xcodeproj/project.pbxproj"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$(dirname "$BUILD_NUMBER_FILE")"

read_project_setting() {
  local key="$1"
  awk -v key="$key" '
    $0 ~ key" = " {
      value = $3
      gsub(/;/, "", value)
      print value
      exit
    }
  ' "$PROJECT_FILE"
}

PROJECT_MARKETING_VERSION="$(read_project_setting MARKETING_VERSION)"
DEFAULT_BUILD_NUMBER="$(read_project_setting CURRENT_PROJECT_VERSION)"

if [[ -f "$BUILD_NUMBER_FILE" ]]; then
  CURRENT_BUILD_NUMBER="$(tr -d '[:space:]' < "$BUILD_NUMBER_FILE")"
else
  CURRENT_BUILD_NUMBER="$DEFAULT_BUILD_NUMBER"
fi

if [[ ! "$CURRENT_BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "Invalid build number in $BUILD_NUMBER_FILE: $CURRENT_BUILD_NUMBER" >&2
  exit 1
fi

NEXT_BUILD_NUMBER=$((CURRENT_BUILD_NUMBER + 1))

xcodebuild \
  -project "$ROOT_DIR/MyataStaticMenuSwift.xcodeproj" \
  -scheme MyataStaticMenuSwift \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  MARKETING_VERSION="$PROJECT_MARKETING_VERSION" \
  CURRENT_PROJECT_VERSION="$NEXT_BUILD_NUMBER" \
  build

printf '%s\n' "$NEXT_BUILD_NUMBER" > "$BUILD_NUMBER_FILE"

rm -rf "$TARGET_APP"
cp -R "$SOURCE_APP" "$TARGET_APP"

echo "Built release app:"
echo "$TARGET_APP"
echo "Version: $PROJECT_MARKETING_VERSION ($NEXT_BUILD_NUMBER)"
