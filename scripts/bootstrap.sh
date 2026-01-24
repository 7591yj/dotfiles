#!/usr/bin/env bash
set -euo pipefail

fatal() {
  printf 'fatal: %s\n' "$*" >&2
  exit 1
}

_self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_source_first() {
  local f
  for f in "$@"; do
    if [[ -r "$f" ]]; then
      # shellcheck disable=SC1090
      . "$f"
      return 0
    fi
  done
  fatal "missing required script: ${1##*/}"
}

_repo_root() {
  if [[ -d "$_self_dir/pkgs" ]]; then
    (cd "$_self_dir" && pwd)
    return 0
  fi
  if [[ -d "$_self_dir/../pkgs" ]]; then
    (cd "$_self_dir/.." && pwd)
    return 0
  fi

  local top
  if command -v git >/dev/null 2>&1; then
    top="$(git -C "$_self_dir" rev-parse --show-toplevel 2>/dev/null || true)"
    if [[ -n "$top" && -d "$top/pkgs" ]]; then
      printf '%s\n' "$top"
      return 0
    fi
  fi

  fatal "cannot determine repo root (pkgs/ not found)"
}

REPO_ROOT="$(_repo_root)"

_source_first \
  "$_self_dir/utils/lib.sh" \
  "$REPO_ROOT/scripts/utils/lib.sh" \
  "$REPO_ROOT/utils/lib.sh"

_source_first \
  "$_self_dir/utils/detect.sh" \
  "$REPO_ROOT/scripts/utils/detect.sh" \
  "$REPO_ROOT/utils/detect.sh"

_source_first \
  "$_self_dir/detect_hw.sh" \
  "$REPO_ROOT/scripts/detect_hw.sh" \
  "$REPO_ROOT/detect_hw.sh"

_source_first \
  "$_self_dir/install_pkgs.sh" \
  "$REPO_ROOT/scripts/install_pkgs.sh" \
  "$REPO_ROOT/install_pkgs.sh"

_source_first \
  "$_self_dir/services.sh" \
  "$REPO_ROOT/scripts/services.sh" \
  "$REPO_ROOT/services.sh"

_source_first \
  "$_self_dir/apply_stow.sh" \
  "$REPO_ROOT/scripts/apply_stow.sh" \
  "$REPO_ROOT/apply_stow.sh"

_source_first \
  "$_self_dir/apply_system_files.sh" \
  "$REPO_ROOT/scripts/apply_system_files.sh" \
  "$REPO_ROOT/apply_system_files.sh"

trap 'die "bootstrap failed (line $LINENO)"' ERR

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  die "run bootstrap as a user; it will use sudo for root steps"
fi

if have_cmd flock; then
  exec 9>"/tmp/dotfiles-bootstrap.lock"
  flock -n 9 || die "another bootstrap is already running"
fi

[[ -d "$REPO_ROOT/pkgs" ]] || die "missing dir: $REPO_ROOT/pkgs"
[[ -d "$REPO_ROOT/stow" ]] || die "missing dir: $REPO_ROOT/stow"
[[ -d "$REPO_ROOT/services" ]] || die "missing dir: $REPO_ROOT/services"
[[ -d "$REPO_ROOT/systemd" ]] || die "missing dir: $REPO_ROOT/systemd"

_is_interactive() {
  [[ -t 0 && -t 1 ]]
}

_resolve_role() {
  local r="${ROLE:-}"

  if [[ -n "$r" ]]; then
    case "$r" in
    desktop | server) printf '%s\n' "$r" ;;
    *) die "invalid ROLE: $r (expected desktop|server)" ;;
    esac
    return 0
  fi

  if [[ "${NONINTERACTIVE:-0}" != 0 ]] || ! _is_interactive; then
    printf '%s\n' "$(default_role)"
    return 0
  fi

  local ans=""
  printf 'role [desktop/server] (default: desktop): ' >&2
  IFS= read -r ans || true
  ans="${ans:-desktop}"

  case "$ans" in
  desktop | server) printf '%s\n' "$ans" ;;
  *) die "invalid role selection: $ans" ;;
  esac
}

_read_lines_into_array() {
  local -n _out="$1"
  local file="$2"
  local mode="${3:-required}"

  _out=()
  if [[ "$mode" == "optional" ]]; then
    if [[ ! -f "$file" ]]; then
      return 0
    fi
    mapfile -t _out < <(read_manifest --optional "$file")
    return 0
  fi

  mapfile -t _out < <(read_manifest --required "$file")
}

_concat_arrays() {
  local -n _dst="$1"
  shift
  local _src_name
  for _src_name in "$@"; do
    local -n _src="$_src_name"
    _dst+=("${_src[@]}")
  done
}

_install_flatpaks() {
  local list_file="$REPO_ROOT/pkgs/flatpak.txt"
  [[ -f "$list_file" ]] || return 0

  local apps=()
  mapfile -t apps < <(read_manifest --optional "$list_file")
  [[ ${#apps[@]} -gt 0 ]] || return 0

  if ! have_cmd flatpak; then
    case "$DISTRO" in
    arch)
      need_cmd pacman
      as_root pacman -S --needed --noconfirm flatpak
      ;;
    fedora)
      need_cmd dnf
      as_root dnf install -y flatpak
      ;;
    *)
      die "flatpak requested but unsupported distro: $DISTRO"
      ;;
    esac
  fi

  as_root flatpak remote-add --if-not-exists \
    flathub https://flathub.org/repo/flathub.flatpakrepo

  local app
  for app in "${apps[@]}"; do
    as_root flatpak install -y --noninteractive flathub "$app"
  done
}

DISTRO="$(distro)"
[[ "$DISTRO" != "unknown" ]] || die "unsupported distro"

ROLE="$(_resolve_role)"

CPU_VENDOR="$(cpu_vendor)"
GPU_PRESENT="$(gpu_vendor_present)"
GPU_ACTIVE="$(gpu_vendor_active)"

log "plan: repo=$REPO_ROOT distro=$DISTRO role=$ROLE cpu=$CPU_VENDOR gpu=$GPU_ACTIVE"

if [[ "${SKIP_PKGS:-0}" == 0 ]]; then
  log "step: install packages"

  case "$DISTRO" in
  arch)
    local_base="$REPO_ROOT/pkgs/arch/base.txt"
    local_role="$REPO_ROOT/pkgs/arch/$ROLE.txt"
    local_cpu="$REPO_ROOT/pkgs/arch/cpu/$CPU_VENDOR.txt"
    local_gpu="$REPO_ROOT/pkgs/arch/gpu/$GPU_ACTIVE.txt"
    local_aur_base="$REPO_ROOT/pkgs/arch/base-aur.txt"
    local_aur_desktop="$REPO_ROOT/pkgs/arch/desktop-aur.txt"

    pac_base=()
    pac_role=()
    pac_cpu=()
    pac_gpu=()
    aur_base=()
    aur_role=()

    _read_lines_into_array pac_base "$local_base" required
    _read_lines_into_array pac_role "$local_role" required
    _read_lines_into_array pac_cpu "$local_cpu" optional
    _read_lines_into_array pac_gpu "$local_gpu" optional
    _read_lines_into_array aur_base "$local_aur_base" required

    if [[ "$ROLE" == "desktop" ]]; then
      _read_lines_into_array aur_role "$local_aur_desktop" required
    fi

    pacman_pkgs=()
    aur_pkgs=()
    _concat_arrays pacman_pkgs pac_base pac_role pac_cpu pac_gpu
    _concat_arrays aur_pkgs aur_base aur_role

    log "pkgs: pacman=${#pacman_pkgs[@]} aur=${#aur_pkgs[@]}"

    install_arch_pacman "${pacman_pkgs[@]}"
    if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
      install_arch_aur "${aur_pkgs[@]}"
    fi
    ;;
  fedora)
    local_base="$REPO_ROOT/pkgs/fedora/base.txt"
    local_role="$REPO_ROOT/pkgs/fedora/$ROLE.txt"

    dnf_base=()
    dnf_role=()
    _read_lines_into_array dnf_base "$local_base" required
    _read_lines_into_array dnf_role "$local_role" required

    dnf_pkgs=()
    _concat_arrays dnf_pkgs dnf_base dnf_role

    log "pkgs: dnf=${#dnf_pkgs[@]}"
    install_fedora "${dnf_pkgs[@]}"
    ;;
  *)
    die "unsupported distro: $DISTRO"
    ;;
  esac

  if [[ "${SKIP_FLATPAK:-0}" == 0 ]]; then
    log "step: install flatpaks"
    _install_flatpaks
  fi
else
  log "step: install packages (skipped)"
fi

if [[ "${SKIP_SYSTEM_FILES:-0}" == 0 ]]; then
  log "step: apply system files"
  overlays=()
  mapfile -t overlays < <(select_system_overlays "$ROLE" "$GPU_ACTIVE")
  apply_system_files "$REPO_ROOT" "${overlays[@]}"
else
  log "step: apply system files (skipped)"
fi

if [[ "${SKIP_SERVICES:-0}" == 0 ]]; then
  log "step: enable services"
  enable_services_from_manifests "$REPO_ROOT" "$DISTRO" "$ROLE"
else
  log "step: enable services (skipped)"
fi

if [[ "${SKIP_STOW:-0}" == 0 ]]; then
  log "step: apply stow"
  target="${STOW_TARGET:-$HOME}"
  stow_dirs=("common")

  case "$ROLE" in
  desktop)
    stow_dirs+=("desktop/apps" "desktop/wm")
    ;;
  server)
    stow_dirs+=("server")
    ;;
  *)
    die "invalid role: $ROLE"
    ;;
  esac

  apply_stow "$REPO_ROOT" "$target" "${stow_dirs[@]}"
else
  log "step: apply stow (skipped)"
fi
