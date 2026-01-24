#!/usr/bin/env bash
set -euo pipefail

_self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=utils/lib.sh
. "$_self_dir/lib.sh"
# shellcheck source=utils/detect.sh
. "$_self_dir/detect.sh"

install_pciutils() {
  d="$(distro)"

  case "$d" in
  arch)
    need_cmd pacman
    as_root pacman -S --needed --noconfirm pciutils
    ;;
  fedora)
    need_cmd dnf
    as_root dnf install -y pciutils
    ;;
  *)
    die "Unsupported distro: $d"
    ;;
  esac
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || die "Do not execute utils/*.sh! Intended to be sourced only."
