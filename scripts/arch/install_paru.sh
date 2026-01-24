#!/usr/bin/env bash
set -euo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils/lib.sh"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils/detect.sh"

install_paru() {
  [[ "$(distro)" == "arch" ]] || die "Not an Arch system"
  [[ ${EUID:-$(id -u)} -ne 0 ]] || die "Run as user only!"

  need_cmd git
  need_cmd makepkg
  need_cmd pacman

  if command -v rustup >/dev/null 2>&1; then
    if ! rustup toolchain list | grep -q '^stable'; then
      rustup toolchain install stable
      rustup default stable
    fi
  fi
  as_root pacman -S --needed --noconfirm base-devel

  (
    local tmp
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"
    git clone --depth 1 https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
  )
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || die "Do not execute arch/*.sh! Intended to be sourced only."
