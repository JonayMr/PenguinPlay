#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]] || ! command -v pacman >/dev/null 2>&1; then
  printf 'Este instalador prepara UxPlay en Arch Linux o derivadas con pacman.\n' >&2
  exit 1
fi

if [[ "$(id -u)" -eq 0 ]]; then
  printf 'No ejecutes este script como root; la compilación se instala en tu usuario.\n' >&2
  exit 1
fi

required=(git cmake gcc pkgconf openssl libplist avahi gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-libav)
missing=()
for package in "${required[@]}"; do
  pacman -Q "$package" >/dev/null 2>&1 || missing+=("$package")
done

if ((${#missing[@]})); then
  printf 'Faltan dependencias de sistema: %s\n' "${missing[*]}"
  printf 'Instálalas con: sudo pacman -S --needed %s\n' "${missing[*]}"
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

printf '\nUxPlay quedó instalado en %s/.local/bin/uxplay\n' "$HOME"
printf 'Avahi debe estar activo para que iOS encuentre el receptor en la red.\n'