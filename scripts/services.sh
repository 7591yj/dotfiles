#!/usr/bin/env bash

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils/lib.sh"

_service_exists() {
  local svc="$1"
  systemctl cat "$svc" >/dev/null 2>&1
}

enable_services() {
  need_cmd systemctl
  local svc
  for svc in "$@"; do
    if ! _service_exists "$svc"; then
      warn "missing unit: $svc (skipping)"
      continue
    fi
    as_root systemctl enable --now "$svc"
  done
}

enable_services_from_manifests() {
  local repo_root="$1"
  local distro="$2"
  local role="$3"

  [[ -n "$repo_root" ]] || die "enable_services_from_manifests: repo_root"
  [[ -n "$distro" ]] || die "enable_services_from_manifests: distro"
  [[ -n "$role" ]] || die "enable_services_from_manifests: role"

  local base="$repo_root/services/$distro/base.txt"
  local role_file="$repo_root/services/$distro/$role.txt"

  local services=()
  local line

  while IFS= read -r line; do
    services+=("$line")
  done < <(read_manifest --optional "$base")

  while IFS= read -r line; do
    services+=("$line")
  done < <(read_manifest --optional "$role_file")

  [[ ${#services[@]} -gt 0 ]] || return 0
  enable_services "${services[@]}"
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || die "Do not execute services.sh! Intended to be sourced only."
