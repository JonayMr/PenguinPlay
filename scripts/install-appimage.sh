#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
appimage_source="$project_dir/dist/PenguinPlay-0.1.0.AppImage"
appimage_dir="$HOME/.local/opt/penguinplay"
appimage_path="$appimage_dir/PenguinPlay.AppImage"
icon_dir="$HOME/.local/share/icons/hicolor/scalable/apps"
icon_path="$icon_dir/penguinplay.svg"
desktop_dir="$HOME/.local/share/applications"
desktop_path="$desktop_dir/penguinplay.desktop"

if [[ ! -x "$appimage_source" ]]; then
  printf 'Packaged AppImage not found: %s\n' "$appimage_source" >&2
  printf 'Run npm ci and npm run dist first.\n' >&2
  exit 1
fi

mkdir -p "$appimage_dir" "$icon_dir" "$desktop_dir"
install -m 755 "$appimage_source" "$appimage_path"
install -m 644 "$project_dir/assets/penguinplay.svg" "$icon_path"
sed -e "s|@APPIMAGE_PATH@|$appimage_path|g" -e "s|@ICON_PATH@|$icon_path|g" \
  "$project_dir/packaging/penguinplay.desktop.in" > "$desktop_path"
chmod 644 "$desktop_path"

if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "$desktop_path"
fi
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$desktop_dir" || true
fi

printf 'PenguinPlay installed. Launch it from Caelestia with Meta+Space.\n'
printf 'Launcher: %s\n' "$desktop_path"