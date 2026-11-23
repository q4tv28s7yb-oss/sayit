#!/usr/bin/env bash
# sayit 卸载脚本：默认只删命令入口，加 --purge 连配置、缓存一起删
set -euo pipefail

SAYIT_HOME=${SAYIT_HOME:-$HOME/.sayit}
PREFIX=${SAYIT_PREFIX:-$HOME/.local/bin}

info() { printf '\033[36m%s\033[0m\n' "$*"; }

if [ -f "$PREFIX/sayit" ]; then
  rm -f "$PREFIX/sayit"
  info "已删除 $PREFIX/sayit"
else
  info "$PREFIX/sayit 不存在，跳过"
fi

if [ "${1:-}" = "--purge" ]; then
  rm -rf "$SAYIT_HOME"
  if [ "$(uname -s)" = "Darwin" ]; then
    rm -rf "$HOME/Library/Caches/sayit"
  else
    rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/sayit"
  fi
  info "已删除配置、虚拟环境与缓存"
else
  info "配置与缓存保留。要一起清除：$0 --purge"
fi
