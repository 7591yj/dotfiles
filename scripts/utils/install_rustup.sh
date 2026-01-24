#!/usr/bin/env bash

_self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=utils/lib.sh
. "$_self_dir/lib.sh"
# shellcheck source=utils/detect.sh
. "$_self_dir/detect.sh"

ensure_rustup_installed() {
  local d
  d="$(distro)"

  if have_cmd rustup; then
    return 0
  fi

  case "$d" in
  arch)
    need_cmd pacman
    as_root pacman -S --needed --noconfirm rustup
    ;;
  fedora)
    need_cmd dnf
    as_root dnf install -y rustup
    ;;
  *)
    die "ensure_rustup_installed: unsupported distro: $d"
    ;;
  esac
}

ensure_rustup_stable() {
  [[ ${EUID:-$(id -u)} -ne 0 ]] || die "rustup must be configured as a user"

  ensure_rustup_installed
  need_cmd rustup

  if [[ "${DRY_RUN:-0}" != 0 ]]; then
    log "dryrun: rustup toolchain install stable --profile minimal"
    log "dryrun: rustup default stable"
    return 0
  fi

  rustup toolchain install stable --profile minimal
  rustup default stable
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || die "Do not execute utils/*.sh! Intended to be sourced only."
