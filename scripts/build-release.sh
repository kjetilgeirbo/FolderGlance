#!/bin/bash
set -euo pipefail

VERSION="${1:-1.0.0}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/.build-release"
APP_NAME="FolderGlance"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="$APP_NAME-$VERSION.dmg"
DMG_PATH="$PROJECT_DIR/$DMG_NAME"

echo "==> Building $APP_NAME v$VERSION (release)..."

# Clean previous build artifacts
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build universal binary (both Apple Silicon and Intel)
cd "$PROJECT_DIR"
swift build -c release --arch arm64 --arch x86_64 2>&1

BINARY="$PROJECT_DIR/.build/apple/Products/Release/$APP_NAME"
if [ ! -f "$BINARY" ]; then
    echo "ERROR: Universal binary not found at $BINARY"
    echo "Trying single-arch build..."
    swift build -c release 2>&1
    BINARY="$(find "$PROJECT_DIR/.build" -name "$APP_NAME" -path "*/release/*" -type f | head -1)"
    if [ ! -f "$BINARY" ]; then
        echo "ERROR: Could not find release binary"
        exit 1
    fi
fi

echo "==> Binary: $BINARY"
echo "    Size: $(du -h "$BINARY" | cut -f1)"
file "$BINARY"

# Create .app bundle
echo "==> Creating $APP_NAME.app..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.kjetilge.FolderGlance</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# Copy app icon
if [ -f "$PROJECT_DIR/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    echo "==> App icon added"
fi

# Ad-hoc code sign
echo "==> Signing..."
codesign --force --sign - "$APP_BUNDLE"

# Create DMG
echo "==> Creating DMG..."
STAGING="$BUILD_DIR/dmg-staging"
rm -rf "$STAGING"
mkdir -p "$STAGING"

cp -R "$APP_BUNDLE" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

rm -f "$DMG_PATH"
hdiutil create \
    -volname "$APP_NAME $VERSION" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$DMG_PATH" 2>&1

# Cleanup
rm -rf "$BUILD_DIR"

echo ""
echo "==> Done!"
echo "    DMG: $DMG_PATH"
echo "    Size: $(du -h "$DMG_PATH" | cut -f1)"
echo ""
echo "    To install: Open the DMG and drag FolderGlance to Applications."
