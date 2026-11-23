#!/usr/bin/env bash
# sayit 安装脚本：建虚拟环境、装依赖、装命令行入口
set -euo pipefail

SAYIT_HOME=${SAYIT_HOME:-$HOME/.sayit}
PREFIX=${SAYIT_PREFIX:-$HOME/.local/bin}
SRC_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

info() { printf '\033[36m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*"; }
die()  { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

command -v python3 >/dev/null 2>&1 || die "需要 python3（macOS: brew install python3；Debian/Ubuntu: sudo apt install python3 python3-venv）"

PY_VER=$(python3 -c 'import sys;print("%d.%d"%sys.version_info[:2])')
info "python $PY_VER · 安装目录 $SAYIT_HOME"

mkdir -p "$SAYIT_HOME/lib" "$PREFIX"

if [ ! -d "$SAYIT_HOME/venv" ]; then
  info "创建虚拟环境…"
  python3 -m venv "$SAYIT_HOME/venv"
fi
info "安装 edge-tts（首次需要联网）…"
"$SAYIT_HOME/venv/bin/pip" install -q --upgrade pip >/dev/null 2>&1 || true
"$SAYIT_HOME/venv/bin/pip" install -q --upgrade edge-tts

info "安装辅助脚本…"
cp "$SRC_DIR/lib/normalize.py" "$SAYIT_HOME/lib/normalize.py"
cp "$SRC_DIR/lib/chunk.py" "$SAYIT_HOME/lib/chunk.py"

if [ ! -f "$SAYIT_HOME/config.env" ]; then
  cp "$SRC_DIR/config.example.env" "$SAYIT_HOME/config.env"
  info "写入默认配置 $SAYIT_HOME/config.env"
fi
if [ ! -f "$SAYIT_HOME/lexicon.txt" ]; then
  cp "$SRC_DIR/lexicon.example.txt" "$SAYIT_HOME/lexicon.txt"
  info "写入读音纠错表 $SAYIT_HOME/lexicon.txt"
fi

install -m 0755 "$SRC_DIR/sayit" "$PREFIX/sayit"
info "命令行入口 $PREFIX/sayit"

# 检查播放器
PLAYER=""
for c in afplay paplay aplay ffplay mpv play; do
  command -v "$c" >/dev/null 2>&1 && { PLAYER="$c"; break; }
done
if [ -z "$PLAYER" ]; then
  case "$(uname -s)" in
    Darwin) warn "未找到播放器，macOS 自带 afplay 理论上一定存在，请检查系统" ;;
    *) warn "未找到播放器，请安装其一：sudo apt install pulseaudio-utils / alsa-utils / ffmpeg" ;;
  esac
else
  info "播放器 $PLAYER"
fi

# 检查 PATH
case ":$PATH:" in
  *":$PREFIX:"*) ;;
  *) warn "目录 $PREFIX 不在 PATH 里，请把下面一行加进 ~/.zshrc 或 ~/.bashrc："
     printf '\n  export PATH="%s:$PATH"\n\n' "$PREFIX" ;;
esac

cat <<EOF

安装完成。试一句：

  sayit "安装成功，这是 sayit 的默认音色"
  sayit -l          # 查看可用中文音色
  sayit -h          # 全部参数

配置文件：$SAYIT_HOME/config.env
纠错词表：$SAYIT_HOME/lexicon.txt
缓存目录：$(uname -s | grep -q Darwin && echo "$HOME/Library/Caches/sayit" || echo "${XDG_CACHE_HOME:-$HOME/.cache}/sayit")
EOF
