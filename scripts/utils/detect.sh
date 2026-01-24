#!/usr/bin/env bash

_self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -r "$_self_dir/lib.sh" ]]; then
  # shellcheck source=utils/lib.sh
  . "$_self_dir/lib.sh"
else
  # shellcheck disable=SC1091
  . "$_self_dir/../utils/lib.sh"
fi

distro() {
  [[ -r /etc/os-release ]] || {
    echo unknown
    return 0
  }
  . /etc/os-release

  case "${ID:-}" in
  arch | archlinux) echo arch ;;
  fedora) echo fedora ;;
  *) echo unknown ;;
  esac
}

default_role() {
  echo "desktop"
}

role() { default_role; }

[[ "${BASH_SOURCE[0]}" != "$0" ]] || die "Do not execute utils/*.sh! Intended to be sourced only."
