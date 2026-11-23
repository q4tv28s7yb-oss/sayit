#!/usr/bin/env python3
"""sayit 文本规范化：把 Markdown / 链接 / emoji / 代码块转成适合朗读的中文口语文本。

用法: python normalize.py [lexicon.txt]  < 原文
"""
import os
import re
import sys


def load_lexicon(path):
    rules = []
    if not path or not os.path.exists(path):
        return rules
    with open(path, encoding="utf-8") as fh:
        for raw in fh:
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            src, dst = line.split("=", 1)
            if src:
                rules.append((src, dst))
    # 长词优先，避免短词把长词拆坏
    rules.sort(key=lambda r: -len(r[0]))
    return rules


def normalize(text, rules):
    # 代码块整体不读，只留提示
    text = re.sub(r"```.*?```", "，代码片段，", text, flags=re.S)
    text = re.sub(r"~~~.*?~~~", "，代码片段，", text, flags=re.S)
    # 行内代码去掉反引号
    text = re.sub(r"`([^`]{0,80})`", r"\1", text)
    # 图片 / 链接
    text = re.sub(r"!\[[^\]]*\]\([^)]*\)", "", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"[（(]\s*https?://[^)）\s]+\s*[)）]", "，链接，", text)
    text = re.sub(r"https?://\S+?(?=[，。；、！？,;）)\s]|$)", " 链接 ", text)
    # 表格竖线读成停顿
    text = text.replace("|", "，")
    # 强调、标题、引用符号
    text = re.sub(r"[*_#>~=]+", "", text)
    text = re.sub(r"^-{3,}$", "", text, flags=re.M)
    # 列表符号
    text = re.sub(r"(?m)^\s*[-+•·▪◦]\s*", "", text)
    text = re.sub(r"(?m)^\s*(\d+)\s*[.、)]\s*", r" 第\1，", text)
    # emoji 与零宽字符
    text = re.sub(
        "[\U0001F000-\U0001FAFF\U00002600-\U000027BF\U0001F1E6-\U0001F1FF"
        "\U0000FE00-\U0000FE0F\U0000200B-\U0000200F\U0000200D]",
        "",
        text,
    )
    # 数字 + 存储单位
    text = re.sub(r"(\d+(?:\.\d+)?)\s*(?:GB|G)\b", r"\1 吉字节", text, flags=re.I)
    text = re.sub(r"(\d+(?:\.\d+)?)\s*(?:MB|M)\b", r"\1 兆字节", text, flags=re.I)
    text = re.sub(r"(\d+(?:\.\d+)?)\s*(?:KB|K)\b", r"\1 千字节", text, flags=re.I)
    # 换行 → 句末停顿
    text = re.sub(r"[ \t\u00a0]+", " ", text)
    text = re.sub(r"\n\s*\n+", "。", text)
    text = re.sub(r"\n", "。", text)
    # 标点收敛、去掉标点两侧多余空格
    text = re.sub(r"[，、,]{2,}", "，", text)
    text = re.sub(r"[。！？；]{2,}", "。", text)
    text = re.sub(r"。?[，、,]+。", "。", text)
    text = re.sub(r"。[，、,]+", "。", text)
    text = re.sub(r"\s*([，。！？；、：（）])\s*", r"\1", text)
    text = re.sub(r"[（(]\s*[)）]", "", text)
    text = re.sub(r"链接[\s，、]*链接", "链接", text)
    text = re.sub(r"^[，。、\s]+", "", text)
    text = re.sub(r"\s+", " ", text)
    # 词表替换
    for src, dst in rules:
        text = text.replace(src, dst)
    return text.strip()


def main():
    rules = load_lexicon(sys.argv[1] if len(sys.argv) > 1 else None)
    raw = sys.stdin.read()
    out = normalize(raw, rules)
    if not out:
        return
    # 没有句末标点时补一个，让语调收得自然
    if out[-1] not in "。！？；：…、,.!?;:）)」』”\"":
        out += "。"
    sys.stdout.write(out)


if __name__ == "__main__":
    main()
