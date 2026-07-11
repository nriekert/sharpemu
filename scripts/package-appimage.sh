#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later

set -e

die() { echo "$*" >&2; exit 1; }

REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${REPO}/artifacts/appimage"

CONF="${1:-Release}"

command -v dotnet >/dev/null || die "dotnet not found"
if command -v magick >/dev/null; then
    CONVERT="magick convert"
elif command -v convert >/dev/null; then
    CONVERT="convert"
else
    die "ImageMagick not found"
fi

dotnet publish "${REPO}/src/SharpEmu.CLI/SharpEmu.CLI.csproj" \
    -c "$CONF" -r linux-x64 --self-contained true --no-restore \
    || dotnet publish "${REPO}/src/SharpEmu.CLI/SharpEmu.CLI.csproj" \
        -c "$CONF" -r linux-x64 --self-contained true

APPDIR="${OUT}/SharpEmu.AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/icons/hicolor/256x256/apps" \
         "$APPDIR/usr/share/doc/SharpEmu"

PUB="${REPO}/artifacts/publish/SharpEmu.CLI/${CONF}/net10.0/linux-x64"
cp -a "$PUB/." "$APPDIR/usr/bin/"
cp "${REPO}/scripts/appimage/AppRun" "$APPDIR/AppRun"
chmod +x "$APPDIR/AppRun"

cp "${REPO}/assets/SharpEmu.desktop" "$APPDIR/"
cp "${REPO}/assets/SharpEmu.desktop" "$APPDIR/usr/share/applications/"

$CONVERT "${REPO}/assets/images/logo.png" -resize 256x256 "$APPDIR/SharpEmu.png"
cp "$APPDIR/SharpEmu.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/"
cp "${REPO}/LICENSE.txt" "$APPDIR/usr/share/doc/SharpEmu/"

TOOL="${OUT}/appimagetool"
if [ ! -f "$TOOL" ]; then
    echo "Downloading appimagetool..."
    curl -Lo "$TOOL" "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "$TOOL"
fi

"$TOOL" --no-appstream "$APPDIR" "${OUT}/SharpEmu-x86_64.AppImage"
echo "AppImage: ${OUT}/SharpEmu-x86_64.AppImage"
