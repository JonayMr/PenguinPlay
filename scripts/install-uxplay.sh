#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]] || ! command -v pacman >/dev/null 2>&1; then
  printf 'This installer prepares UxPlay on Arch Linux or pacman-based distributions.\n' >&2
  exit 1
fi

if [[ "$(id -u)" -eq 0 ]]; then
  printf 'Do not run this script as root; the build is installed for your user.\n' >&2
  exit 1
fi

required=(git cmake gcc pkgconf openssl libplist avahi gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-libav)
missing=()
for package in "${required[@]}"; do
  pacman -Q "$package" >/dev/null 2>&1 || missing+=("$package")
done

if ((${#missing[@]})); then
  printf 'Missing system dependencies: %s\n' "${missing[*]}"
  printf 'Install them with: sudo pacman -S --needed %s\n' "${missing[*]}"
  exit 2
fi

build_dir="${XDG_CACHE_HOME:-$HOME/.cache}/penguinplay/uxplay"
mkdir -p "$(dirname "$build_dir")"
if [[ -d "$build_dir/.git" ]]; then
  git -C "$build_dir" fetch --depth 1 origin tag v1.73.7
  git -C "$build_dir" checkout --detach v1.73.7
else
  git clone --depth 1 --branch v1.73.7 https://github.com/FDH2/UxPlay "$build_dir"
fi

cmake -S "$build_dir" -B "$build_dir/build" -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build "$build_dir/build" --parallel "$(nproc)"
cmake --install "$build_dir/build"

printf '\nUxPlay was installed to %s/.local/bin/uxplay\n' "$HOME"
printf 'Avahi must be running for iOS devices to discover the receiver.\n'