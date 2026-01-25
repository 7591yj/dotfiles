#!/usr/bin/env bash

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils/lib.sh"

apply_stow() {
  local repo_root="$1"
  local target="$2"
  shift 2
  local dirs=("$@")

  need_cmd stow
  [[ -d "$repo_root/stow" ]] || die "Missing stow directory: $repo_root/stow"

  local d
  for d in "${dirs[@]}"; do
    [[ -d "$repo_root/stow/$d" ]] || continue
    (cd "$repo_root/stow" && stow --restow --target "$target" "$d")
    (
      cd "$repo_root/stow" || exit 1
      run stow --restow --target "$target" "$d"
    ) || die "stow failed: pkg=$d target=$target"
  done
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || die "Do not execute apply_stow.sh! Intended to be sourced only."
