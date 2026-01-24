#!/usr/bin/env bash

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils/lib.sh"

select_system_overlays() {
  local role="${1:-}"
  local gpu_active="${2:-unknown}"

  [[ -n "$role" ]] || die "select_system_overlays: role"

  printf '%s\n' "common"
  printf '%s\n' "$role"

  if [[ "$gpu_active" == "nvidia" ]]; then
    printf '%s\n' "nvidia-suspend"
  fi
}

apply_system_files() {
  local repo_root="$1"
  shift

  [[ -n "$repo_root" ]] || die "apply_system_files: repo_root"
  [[ -d "$repo_root/systemd" ]] || die "missing dir: $repo_root/systemd"

  need_cmd cp
  need_cmd systemctl

  local need_udev_reload=0
  local overlay
  local src

  for overlay in "$@"; do
    src="$repo_root/systemd/$overlay"
    [[ -d "$src" ]] || continue

    if [[ -d "$src/etc/udev/rules.d" ]]; then
      need_udev_reload=1
    fi

    log "apply system overlay: $overlay"
    as_root cp -a "$src/." /
  done

  as_root systemctl daemon-reload

  if ((need_udev_reload)); then
    if have_cmd udevadm; then
      as_root udevadm control --reload-rules
      as_root udevadm trigger
    else
      warn "udevadm missing; udev rules reloaded skipped"
    fi
  fi

  if have_cmd selinuxenabled && selinuxenabled; then
    if have_cmd restorecon; then
      as_root restorecon -RF /etc/systemd/system || true
      as_root restorecon -RF /etc/udev/rules.d || true
      as_root restorecon -RF /usr/local/bin || true
    fi
  fi
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || die "Do not execute apply_system_files.sh! Intended to be sourced only."
