#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="${1:-source}"

out() {
  local dir="$1"
  if [ -d "$dir" ]; then
    echo "# Directory: $dir"
    # 仅对普通文件计算 SHA256
    find "$dir" -type f -print0 | xargs -0 -I{} sha256sum "{}"
    echo
  fi
}

# 典型可能含二进制或打包产物的目录
out "${SRC_DIR}/bin"
out "${SRC_DIR}/dist"
out "${SRC_DIR}/build"
out "${SRC_DIR}/out"
out "${SRC_DIR}/release"
