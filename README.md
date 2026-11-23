# sayit

**命令行语音播报，把 AI 回复念出来，不卡终端。**

用微软 Edge 的神经网络音色（`zh-CN-XiaoxiaoNeural` 等 8 个中文音色），本地缓存秒播，长文本边播边合成，断网自动回退系统语音。一条命令装好，一个命令播报。

```
sayit -b "构建完成，耗时 42 秒"
```

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash%204%2B-89e051.svg)]()
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg)]()

---

## 为什么不是又一个 `edge-tts` 包装

GitHub 上现成的方案大多是「合成 mp3 + `afplay`」两行脚本：每次都等整段合成完才出声，重复内容重复请求，断网就哑火或者退成英文机械音。sayit 补的是这几块：

| 场景 | 常见包装 | sayit |
|---|---|---|
| 长文本首句出声 | 整段合成完才播，约 4 s | **2.2 s**（播第一句时后台合成下一句） |
| 重复播报 | 每次重新请求，约 4 s | **0.2 s**（本地缓存直接播） |
| 播报占终端 | 播完才返回 | `-b` 后台播报，**0.28 s 返回** |
| 断网 / 服务超时 | 卡住，或回退英文机械音 | 12 s 熔断，回退中文 `Tingting`（Linux 走 espeak-ng） |
| Markdown 输入 | `**加粗**`、`[链接](url)`、emoji 照样念出来 | 自动转口语：去符号、链接读「链接」、`5.9 GB` → `5.9 吉字节` |
| 多条播报叠音 | 两条一起响 | 自动排队，`-i` 可打断 |

数据是在 M2 Max + macOS 26 上实测的，句子长度约 120 字。

## 安装

需要 `bash`、`python3`，以及一个音频播放器（macOS 自带 `afplay`，Linux 装 `paplay` / `aplay` / `ffplay` 之一）。

```bash
git clone https://github.com/q4tv28s7yb-oss/sayit.git
cd sayit
./install.sh
```

脚本会创建 `~/.sayit/venv`、安装 `edge-tts`、把命令装到 `~/.local/bin/sayit`，并生成默认配置。如果 `~/.local/bin` 不在 `PATH` 里，脚本会提示你加一行。

## 用法

```bash
sayit "要播报的文字"                    # 前台播报，播完返回
sayit -b "后台播报，立刻返回"            # 适合收尾提示、构建结果
sayit -i "打断上一条，马上播这条"
sayit -v zh-CN-YunxiNeural "换个男声"     # 临时换音色
sayit -r +15% "说快点"
sayit -g 0.7 "音量七成"
sayit -c "忽略缓存重新合成"
sayit -n "断网时用系统语音"
sayit -l                                # 列出 8 个中文神经音色
sayit -s                                # 看当前配置与缓存占用
echo "**构建完成** 🎉" | sayit           # 也支持管道输入
```

| 参数 | 作用 |
|---|---|
| `-v` | 音色 ID，默认 `zh-CN-XiaoxiaoNeural` |
| `-r` | 语速，`+8%` / `-5%`，默认 `+8%` |
| `-p` | 音调，如 `+2Hz`，默认 `+0Hz` |
| `-g` | 音量 0~1，对 `afplay` 与 `mpv` 生效 |
| `-b` | 后台播报，立即返回 |
| `-i` | 打断当前播放 |
| `-n` | 离线模式，跳过联网合成 |
| `-c` | 不使用缓存 |
| `-d` | 打印调试信息（缓存命中、合成耗时、分句数） |
| `-l` / `-s` | 列音色 / 看配置 |
| `--check` | 音色自检：合成一句并播放，报告是否走了回退 |
| `-h` / `-V` | 帮助 / 版本 |

退出码：`0` 正常；`1` 播放器或合成均不可用；`2` 参数错误。

## 配置

长期设置写 `~/.sayit/config.env`（首次安装时生成）：

```bash
TTS_VOICE="zh-CN-XiaoxiaoNeural"
TTS_RATE="+8%"
TTS_PITCH="+0Hz"
# TTS_GAIN="0.9"
TTS_TIMEOUT="20"        # 单次合成超时，超时即重试，三次失败才回退
TTS_CHUNK_MIN="120"     # 超过这么多字才分句流水线
TTS_FALLBACK_VOICE="Tingting"
TTS_FALLBACK_RATE="180"
```

优先级：命令行参数 > 环境变量（同名 `TTS_*`）> `config.env` > 内置默认值。

读音纠错写 `~/.sayit/lexicon.txt`，一行一条 `出现的词=替换写法`，整词匹配、长词优先。TTS 读不对的多音字、英文缩写在这里改，比如 `WorkBuddy=Work Buddy`。

## 可用音色

| 音色 ID | 性别 | 备注 |
|---|---|---|
| `zh-CN-XiaoxiaoNeural` | 女 | 默认，播报感稳 |
| `zh-CN-XiaoyiNeural` | 女 | 年轻活泼 |
| `zh-CN-YunxiNeural` | 男 | 偏解说 |
| `zh-CN-YunjianNeural` | 男 | 浑厚，适合播报 |
| `zh-CN-YunyangNeural` | 男 | 新闻播音 |
| `zh-CN-YunxiaNeural` | 男 | 少年感 |
| `zh-CN-liaoning-XiaobeiNeural` | 女 | 东北口音 |
| `zh-CN-shaanxi-XiaoniNeural` | 女 | 陕西口音 |

## 工作原理

1. **口语化**：`normalize.py` 把 Markdown、链接、emoji、代码块、表格符号清掉，换行变停顿，数字单位转中文读法，再套一层读音纠错词表。
2. **分句**：`chunk.py` 把超过 80 字的长文本按句切开，合并过短句，避免碎片化。
3. **流水线**：后台线程顺序合成、前台顺序播放，播第 N 句时第 N+1 句已经在生成，所以首句两三秒就出声，句间也没有空档。
4. **缓存**：合成结果按「音色+语速+音调+文本」哈希存 mp3，超过 200 段或 30 天自动淘汰。
5. **重试与熔断回退**：单次请求 20 s 超时，失败自动重试 3 次（间隔 1s、2s），三次仍失败才交给系统语音，并写入 `history.log` 与 `last-error.log`，不会静默降级。

缓存位置：macOS `~/Library/Caches/sayit`，Linux `${XDG_CACHE_HOME:-~/.cache}/sayit`。`history.log` 记录最近播报过的内容，`last-error.log` 留存合成失败原因。

## 接管系统 `say`（可选）

其他脚本或工具直接调用 macOS 的 `say` 时，出来的是系统合成音（明显更机械）。可以让 `sayit` 接管：

```bash
install -m 0755 extras/say-shim.sh ~/.local/bin/say
```

之后 `~/.local/bin` 在 PATH 中排在 `/usr/bin` 前面时，凡是 `say "文本"`、`say -f 文本文件`、`echo 文本 | say` 都会自动改走神经音色；而 `say -o out.aiff`、`say -v ?`、`say --help` 这类需要系统能力的调用原样交给 `/usr/bin/say`。删除 `~/.local/bin/say` 即可恢复原状。

`sayit` 自身的回退固定调用 `/usr/bin/say`，因此不会和转发壳互相递归。

## 兼容性

- macOS：主要开发与验证环境（Apple Silicon + macOS 26），`afplay` 播放，`say` 回退。
- Linux：脚本层面已适配（`paplay` / `aplay` / `ffplay` 播放，`espeak-ng` 回退），未做逐发行版的实机测试，欢迎提 issue。
- Windows：未适配，WSL 下可走 Linux 路径。
- 需要 bash 4+（macOS 自带 3.2 也能跑，脚本未用 bash 4 特性）。

## 隐私说明

`edge-tts` 走微软 Edge 的在线语音服务，**播报文本会发送到微软服务器**。涉密内容请用 `-n` 走本地系统语音。缓存与日志全部留在本机，不上传。

## 卸载

```bash
./uninstall.sh            # 只删命令入口
./uninstall.sh --purge    # 连配置、虚拟环境、缓存一起删
```

## 开发

```bash
make lint     # shellcheck sayit install.sh uninstall.sh
make test     # 语法检查 + 分句/规范化样例断言
make install  # 本机安装
```

辅助脚本是纯 Python 标准库，没有额外依赖，可以单独跑：

```bash
echo "**完成** 5.9 GB" | python3 lib/normalize.py lexicon.example.txt
printf '第一句。第二句。' | python3 lib/chunk.py 80
```

## English

`safe, natural-sounding TTS for your terminal`: neural voices via Microsoft Edge TTS, disk cache for instant replay, sentence-level pipeline so the first words start in ~2 s, `-b` for non-blocking announcements, and a hard timeout that falls back to the OS voice. Install with `./install.sh`, run `sayit -h` for flags. macOS first-class, Linux best-effort.

## License

[Apache-2.0](LICENSE)

## 持续集成

`docs/ci.yml` 是一份可直接用的 GitHub Actions 配置（shellcheck + 冒烟测试）。想启用：

```bash
mkdir -p .github/workflows && cp docs/ci.yml .github/workflows/ci.yml
```

注意：用带 `workflow` 权限的令牌推送，否则 GitHub 会拒绝包含 workflow 文件的提交（`gh auth refresh -s workflow` 可补齐权限）。
