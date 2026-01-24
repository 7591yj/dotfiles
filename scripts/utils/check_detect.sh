#!/usr/bin/env bash
set -euo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils/detect.sh"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils/detect_hw.sh"

cpu_vendor="$(cpu_vendor)"
gpu_vendor="$(gpu_vendor)"
distro="$(distro)"
role="$(role)"

printf 'CPU vendor: %s\n' "$cpu_vendor"
printf 'GPU vendor: %s\n' "$gpu_vendor"
printf 'Role: %s\n' "$role"
printf 'Distro: %s\n' "$distro"
