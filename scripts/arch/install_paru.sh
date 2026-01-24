#!/usr/bin/env bash

_self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
. "$_self_dir/../utils/lib.sh"
# shellcheck disable=SC1091
. "$_self_dir/../utils/detect.sh"
# shellcheck disable=SC1091
. "$_self_dir/../utils/install_rustup.sh"

install_paru() {
  [[ "$(distro)" == "arch" ]] || die "Not an Arch system"
  [[ ${EUID:-$(id -u)} -ne 0 ]] || die "Run as user only!"

  need_cmd git
  need_cmd makepkg
  need_cmd pacman

  as_root pacman -S --needed --noconfirm base-devel rustup
  ensure_rustup_stable

  if have_cmd paru; then
    return 0
  fi

  if [[ "${DRY_RUN:-0}" != 0 ]]; then
    log "dryrun: would build and install paru from AUR"
    return 0
  fi

  (
    export PATH="$HOME/.cargo/bin:$PATH"
    local tmp
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"
    run git clone --depth 1 https://aur.archlinux.org/paru.git
    cd paru
    run makepkg -si --noconfirm
  )
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || die "Do not execute arch/*.sh! Intended to be sourced only."
