#!/usr/bin/env bash

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils/lib.sh"

_ensure_paru() {
  # shellcheck disable=SC1091
  . "$(cd "$(dirname "$0")" && pwd)/arch/install_paru.sh"
  install_paru
  need_cmd paru
}

install_arch_pacman() {
  local pkgs=("$@")

  need_cmd pacman
  # full system upgrade; intended as the script is meant to be run on fresh installations
  as_root pacman -Syu --noconfirm
  [[ ${#pkgs[@]} -gt 0 ]] || return 0
  as_root pacman -S --needed --noconfirm "${pkgs[@]}"
}

install_arch_aur() {
  local pkgs=("$@")
  [[ ${#pkgs[@]} -gt 0 ]] || return 0

  _ensure_paru
  run paru -S --needed --noconfirm "${pkgs[@]}"
}

install_fedora() {
  local pkgs=("$@")
  need_cmd dnf
  # full system upgrade; intended as the script is meant to be run on fresh installations
  as_root dnf -y upgrade --refresh
  as_root dnf -y install "${pkgs[@]}"
}

install_pkgs() {
  local distro="$1"
  [[ -n "$distro" ]] || die "Distro is unknown!"
  shift
  local pkgs=("$@")
  [[ ${#pkgs[@]} -gt 0 ]] || return 0

  case "$distro" in
  arch) install_arch_pacman "${pkgs[@]}" ;;
  fedora) install_fedora "${pkgs[@]}" ;;
  *) die "Distro not supported: $distro" ;;
  esac
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || die "Do not execute install_pkgs.sh! Intended to be sourced only."
