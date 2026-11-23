#!/bin/bash
# say 转发壳：把纯文本播报交给 sayit（神经音色 + 缓存），
# 需要文件输出、列出音色等特殊用法时原样交给系统 /usr/bin/say。
# 删除本文件即可恢复系统 say 的原行为。

REAL="/usr/bin/say"
SAYIT="${SAYIT_BIN:-$HOME/.local/bin/sayit}"

pass() { exec "$REAL" "$@"; }

# 无参数：读管道文本，否则原样交给系统
if [ $# -eq 0 ]; then
  if [ ! -t 0 ]; then
    text="$(cat)"
    [ -z "${text// /}" ] && exit 0
    exec "$SAYIT" "$text"
  fi
  pass
fi

# 这些用法必须由系统 say 处理（写文件、帮助、版本）
case "$1" in
  -o|--output|--output=*|-h|--help|--version) pass "$@" ;;
esac

text=""
rate=""
while [ $# -gt 0 ]; do
  case "$1" in
    -v|--voice)
      [ "${2:-}" = "?" ] && pass "$@"
      shift 2 ;;
    -r|--rate) rate="${2:-}"; shift 2 ;;
    -f|--file)
      shift
      [ -n "${1:-}" ] && [ -f "${1:-}" ] && text="$text $(cat "$1")"
      shift ;;
    --data-format|--file-format) shift 2 ;;
    -*) shift ;;
    *) text="$text $1"; shift ;;
  esac
done

if [ -z "${text// /}" ] && [ ! -t 0 ]; then text="$(cat)"; fi
[ -z "${text// /}" ] && exit 0

args=()
case "$rate" in
  ''|*[!0-9]*) ;;
  *)
    pct=$(((rate - 180) * 100 / 180))
    if [ "$pct" -ge 0 ]; then args+=(-r "+${pct}%"); else args+=(-r "${pct}%"); fi
    ;;
esac

exec "$SAYIT" "${args[@]}" "$text"
