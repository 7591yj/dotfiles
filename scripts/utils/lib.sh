#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'fatal: %s\n' "$*" >&2
  exit 1
}
log() { printf '%s\n' "$*"; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "missing: $1"; }

as_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    "$@"
  else
    need_cmd sudo
    sudo "$@"
  fi
}

read_manifest() {
  # strips comments and empty lines
  sed -e 's/#.*$//' -e '/^[[:space:]]*$/d' "$1"
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || die "Do not execute utils/*.sh! Intended to be sourced only."
