#!/usr/bin/env bash

die() {
  printf 'fatal: %s\n' "$*" >&2
  exit 1
}

warn() { printf 'warn: %s\n' "$*" >&2; }
log() { printf '%s\n' "$*"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }
need_cmd() { have_cmd "$1" || die "missing command: $1"; }

need_file() {
  [[ -f "$1" ]] || die "missing file: $1"
}

is_root() { [[ ${EUID:-$(id -u)} -eq 0 ]]; }

_print_cmd() {
  local arg
  for arg in "$@"; do
    printf '%q ' "$arg"
  done
}

run() {
  if [[ "${DRY_RUN:-0}" != 0 ]]; then
    printf 'dryrun: '
    _print_cmd "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

as_root() {
  if is_root; then
    run "$@"
    return 0
  fi

  need_cmd sudo
  run sudo -- "$@"
}

read_manifest() {
  local mode="required"
  case "${1:-}" in
  --optional)
    mode="optional"
    shift
    ;;
  --required)
    mode="required"
    shift
    ;;
  esac

  local file="${1:-}"
  [[ -n "$file" ]] || die "read_manifest: missing file argument"

  if [[ ! -f "$file" ]]; then
    if [[ "$mode" == "optional" ]]; then
      return 0
    fi
    die "missing manifest: $file"
  fi

  awk '
   {
     sub(/\r$/, "", $0)
     sub(/#.*/, "", $0)
     gsub(/^[ \t]+|[ \t]+$/, "", $0)
     if ($0 == "") next
     if (!seen[$0]++) print $0
   }
 ' "$file"
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || die "Do not execute utils/*.sh! Intended to be sourced only."
