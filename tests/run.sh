#!/usr/bin/env bash
# 不依赖网络与声卡的冒烟测试：语法、文本处理、命令自检
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PY="$(command -v python3)"
PASS=0; FAIL=0

ok()   { PASS=$((PASS + 1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL + 1)); printf '  \033[31m✗\033[0m %s\n     期望: %s\n     实际: %s\n' "$1" "$2" "$3"; }
check() {  # 名称 期望 实际
  [ "$2" = "$3" ] && ok "$1" || bad "$1" "$2" "$3"
}

echo "== 语法 =="
for f in "$ROOT/sayit" "$ROOT/install.sh" "$ROOT/uninstall.sh"; do
  bash -n "$f" && ok "bash -n $(basename "$f")" || bad "bash -n $(basename "$f")" "无错" "语法错误"
done

echo "== 文本规范化 =="
out=$(printf '%s\n' '**完成** 已删除 `pkg`' '- 详见 [说明](https://x.y/z) 🎉' '- 占用 860 MB' |
  "$PY" "$ROOT/lib/normalize.py" "$ROOT/lexicon.example.txt")
check "去 Markdown 与 emoji" "完成 已删除 pkg。详见 说明。占用 860 兆字节。" "$out"

out=$(printf '银行办理业务，需要重新进行行业评估。' | "$PY" "$ROOT/lib/normalize.py" "$ROOT/lexicon.example.txt")
check "词表不误伤多音字" "银行办理业务，需要重新进行行业评估。" "$out"

out=$(printf '没写结尾的一段话' | "$PY" "$ROOT/lib/normalize.py")
check "自动补句末标点" "没写结尾的一段话。" "$out"

echo "== 分句 =="
n=$(printf '第一句。第二句。第三句。第四句。' | "$PY" "$ROOT/lib/chunk.py" 80 | wc -l | tr -d ' ')
check "短文本不分句" "1" "$n"

n=$(printf '语音播报已经升级完成。现在会先把文字自动转成口语，再去合成音频。长句会被切成小段，播第一段的时候后台已经在合成第二段。这样首句出声很快，长时间播报也不会断断续续。缓存会保留最近的两百段音频。' |
  "$PY" "$ROOT/lib/chunk.py" 80 | wc -l | tr -d ' ')
check "长文本切成 3 段" "3" "$n"

echo "== 命令自检 =="
export SAYIT_HOME="$ROOT"   # 直接指向仓库目录，复用仓库内的配置与辅助脚本
"$ROOT/sayit" -V | grep -q "sayit" && ok "-V 输出版本" || bad "-V 输出版本" "sayit x.y.z" "$("$ROOT/sayit" -V)"
"$ROOT/sayit" -h >/dev/null 2>&1 && ok "-h 正常退出" || bad "-h 正常退出" "exit 0" "非零"
"$ROOT/sayit" -s >/dev/null 2>&1 && ok "-s 正常退出" || bad "-s 正常退出" "exit 0" "非零"
"$ROOT/sayit" -z "x" >/dev/null 2>&1; rc=$?
check "未知参数返回 2" "2" "$rc"

printf '\n通过 %d 项，失败 %d 项\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
