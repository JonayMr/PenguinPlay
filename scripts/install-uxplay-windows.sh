#!/usr/bin/env bash
set -euo pipefail

if [[ "${MSYSTEM:-}" != "UCRT64" ]] || [[ -z "${MINGW_PREFIX:-}" ]]; then
  printf 'Open the MSYS2 UCRT64 terminal before running this script.\n' >&2
  exit 1
fi

packages=(
  git
  mingw-w64-ucrt-x86_64-cmake
  mingw-w64-ucrt-x86_64-gcc
  mingw-w64-ucrt-x86_64-ninja
  mingw-w64-ucrt-x86_64-pkgconf
  mingw-w64-ucrt-x86_64-libplist
  mingw-w64-ucrt-x86_64-gstreamer
  mingw-w64-ucrt-x86_64-gst-plugins-base
  mingw-w64-ucrt-x86_64-gst-plugins-good
  mingw-w64-ucrt-x86_64-gst-plugins-bad
  mingw-w64-ucrt-x86_64-gst-libav
)

pacman -S --needed "${packages[@]}"

build_root="${XDG_CACHE_HOME:-$HOME/.cache}/penguinplay"
source_dir="$build_root/UxPlay"
mkdir -p "$build_root"

if [[ -d "$source_dir/.git" ]]; then
  git -C "$source_dir" pull --ff-only
else
  git clone --depth 1 https://github.com/FDH2/UxPlay.git "$source_dir"
fi

cmake -S "$source_dir" -B "$source_dir/build" -G Ninja \
  -DCMAKE_INSTALL_PREFIX="$MINGW_PREFIX" \
  -DUSE_MDNS=1
cmake --build "$source_dir/build" --parallel "$(nproc)"
cmake --install "$source_dir/build"

printf '\nUxPlay installed to %s/bin/uxplay.exe\n' "$MINGW_PREFIX"
printf 'Restart PenguinPlay if it is already open.\n'