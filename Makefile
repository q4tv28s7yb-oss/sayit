SHELL := /bin/bash
PREFIX ?= $(HOME)/.local/bin

.PHONY: help install uninstall lint test

help:
	@echo "make install    安装到 $(PREFIX)"
	@echo "make uninstall  移除命令入口"
	@echo "make lint       shellcheck 静态检查"
	@echo "make test       语法 + 文本处理 + 命令自检"

install:
	SAYIT_PREFIX=$(PREFIX) ./install.sh

uninstall:
	SAYIT_PREFIX=$(PREFIX) ./uninstall.sh

lint:
	@command -v shellcheck >/dev/null || { echo "未安装 shellcheck：brew install shellcheck / apt install shellcheck"; exit 1; }
	shellcheck -S warning sayit install.sh uninstall.sh tests/run.sh

test:
	@bash -n sayit && bash -n install.sh && bash -n uninstall.sh && echo "语法 OK"
	@bash tests/run.sh
