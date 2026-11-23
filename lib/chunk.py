#!/usr/bin/env python3
"""把长文本切成适合逐句合成播报的小段，每行一段。

用法: python chunk.py [最小整句长度，默认 80] < 文本
"""
import re
import sys

SENT_END = "。！？；…\n"


def split_sentences(text):
    parts, buf = [], ""
    for ch in text:
        buf += ch
        if ch in SENT_END:
            parts.append(buf)
            buf = ""
    if buf.strip():
        parts.append(buf)
    return [p.strip() for p in parts if p.strip()]


def split_long(sent, limit):
    if len(sent) <= limit:
        return [sent]
    # 先按逗号/分号断，再按长度硬切
    out, buf = [], ""
    for ch in sent:
        buf += ch
        if ch in "，、：,;" and len(buf) >= limit * 0.5:
            out.append(buf)
            buf = ""
    if buf.strip():
        out.append(buf)
    final = []
    for piece in out:
        while len(piece) > limit:
            cut = piece.rfind("，", 0, limit)
            if cut < limit * 0.4:
                cut = limit
            final.append(piece[:cut])
            piece = piece[cut:]
        if piece.strip():
            final.append(piece)
    return final


def main():
    min_len = int(sys.argv[1]) if len(sys.argv) > 1 else 80
    text = sys.stdin.read().strip()
    if not text:
        return
    sents = split_sentences(text)
    if len(text) <= min_len:
        print(text)
        return
    # 合并过短的句子，避免碎片化播报
    merged, buf = [], ""
    for s in sents:
        buf += s
        if len(buf) >= 24:
            merged.append(buf)
            buf = ""
    if buf.strip():
        if merged:
            merged[-1] += buf
        else:
            merged.append(buf)
    for s in merged:
        for piece in split_long(s, max(min_len, 100)):
            print(piece)


if __name__ == "__main__":
    main()
