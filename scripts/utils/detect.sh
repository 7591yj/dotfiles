#!/usr/bin/env bash
set -euo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

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

role() {
  # heuristic only; real choice persists in state
  if command -v systemd-detect-virt >/dev/null 2>&1; then
    if systemd-detect-virt -q; then
      echo "server"
      return 0
    fi
  fi
  echo "desktop"
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || die "Do not execute utils/*.sh! Intended to be sourced only."
