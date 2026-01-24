#!/usr/bin/env bash

_self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -r "$_self_dir/lib.sh" ]]; then
  # shellcheck disable=SC1091
  . "$_self_dir/lib.sh"
elif [[ -r "$_self_dir/utils/lib.sh" ]]; then
  # shellcheck disable=SC1091
  . "$_self_dir/utils/lib.sh"
else
  # shellcheck disable=SC1091
  . "$_self_dir/../utils/lib.sh"
fi

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

_gpu_vendor_from_sysfs_vendor_id() {
  case "$1" in
  0x10de) echo nvidia ;;
  0x1002) echo amd ;;
  0x8086) echo intel ;;
  *) echo unknown ;;
  esac
}

gpu_vendor_present() {
  local vendor_id
  local seen_nvidia=0
  local seen_amd=0
  local seen_intel=0

  local f
  for f in /sys/class/drm/card*/device/vendor; do
    [[ -r "$f" ]] || continue
    vendor_id="$(tr -d '\n' <"$f" 2>/dev/null || true)"

    case "$(_gpu_vendor_from_sysfs_vendor_id "$vendor_id")" in
    nvidia) seen_nvidia=1 ;;
    amd) seen_amd=1 ;;
    intel) seen_intel=1 ;;
    esac
  done

  if ((seen_nvidia)); then
    echo nvidia
    return 0
  fi
  if ((seen_amd)); then
    echo amd
    return 0
  fi
  if ((seen_intel)); then
    echo intel
    return 0
  fi

  if have_cmd lspci; then
    local line
    line="$(
      lspci -nn 2>/dev/null | awk '
        /VGA compatible controller|3D controller/ {
          print $0
        }
      '
    )"

    case "$line" in
    *NVIDIA*) echo nvidia ;;
    *AMD* | *ATI*) echo amd ;;
    *Intel*) echo intel ;;
    *) echo unknown ;;
    esac
    return 0
  fi

  echo unknown
}

_driver_module_name_for_card() {
  local card_path="$1"
  local mod_link

  mod_link="$(readlink -f "$card_path/device/driver/module" 2>/dev/null || true)"
  [[ -n "$mod_link" ]] || return 1
  basename "$mod_link"
}

_vendor_from_driver_module() {
  case "$1" in
  nvidia | nvidia_drm) echo nvidia ;;
  amdgpu) echo amd ;;
  i915) echo intel ;;
  *) echo unknown ;;
  esac
}

gpu_vendor_active() {
  local card
  local chosen=""

  for card in /sys/class/drm/card*; do
    [[ -d "$card" ]] || continue
    if [[ -r "$card/device/boot_vga" ]]; then
      if [[ "$(tr -d '\n' <"$card/device/boot_vga")" == "1" ]]; then
        chosen="$card"
        break
      fi
    fi
  done

  if [[ -z "$chosen" ]] && [[ -d /sys/class/drm/card0 ]]; then
    chosen="/sys/class/drm/card0"
  fi

  if [[ -n "$chosen" ]]; then
    local mod
    mod="$(_driver_module_name_for_card "$chosen" || true)"
    if [[ -n "$mod" ]]; then
      echo "$(_vendor_from_driver_module "$mod")"
      return 0
    fi
  fi

  if have_cmd lsmod; then
    if lsmod | awk '{ print $1 }' | grep -qx 'nvidia'; then
      echo nvidia
      return 0
    fi
  fi

  gpu_vendor_present
}

gpu_vendor() { gpu_vendor_active; }

[[ "${BASH_SOURCE[0]}" != "$0" ]] || die "Do not execute utils/*.sh! Intended to be sourced only."
