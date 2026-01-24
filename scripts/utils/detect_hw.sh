#!/usr/bin/env bash
set -euo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

cpu_vendor() {
  local v
  v="$(
    awk -F: '/^vendor_id/ {
      gsub(/^[ \t]+/, "", $2)
      print $2
      exit
    }' /proc/cpuinfo
  )"

  case "$v" in
  GenuineIntel) echo intel ;;
  AuthenticAMD) echo amd ;;
  *) echo unknown ;;
  esac
}

gpu_vendor() {
  command -v lspci >/dev/null 2>&1 || {
    echo unknown
    return 0
  }
  local v
  v="$(
    lspci -nn | awk '
      /VGA compatible controller|3D controller/ {
        print $0
        exit
      }
    '
  )"

  case "$v" in
  *NVIDIA*) echo nvidia ;;
  *AMD* | *ATI*) echo amd ;;
  *Intel*) echo intel ;;
  *) echo unknown ;;
  esac
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || die "Do not execute utils/*.sh! Intended to be sourced only."
