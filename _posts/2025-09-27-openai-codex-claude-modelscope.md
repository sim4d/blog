---
title: OpenAI Codex 和 Anthropic Claude 使用魔塔 API
date: 2025-09-27 12:14:12 +0800
toc: true
categories: [AI, Programming]
tags: [Claude Code, OpenAI Codex]
---


# OpenAI Codex 和 Anthropic Claude 配置使用魔塔 API

OpenAI Codex 作为一款快速进化的命令行编程辅助代理，近期新增了第三方模型 API 接口支持，功能更加强大。魔塔社区也推出了针对 Anthropic Claude 的 API 调用 URL（目前处于 Beta 阶段），为用户提供更便捷的配置方式，跳过复杂易错的 CCR 配置流程。本文将简要介绍 OpenAI Codex 和 Anthropic Claude 使用魔塔 API 的安装与配置步骤，并提供一键安装脚本，助您高效上手。

## OpenAI Codex 配置使用魔塔 API 

### 1. 安装
通过 npm 全局安装 Codex：

```bash
npm install -g @openai/codex
```

### 2. 配置
手动创建并编辑 `$HOME/.codex/config.toml` 文件，添加必要的配置项。

```toml

profile = "modelscope"
#profile = "openrouter"

[model_providers.modelscope]
name = "ModelScope"
base_url = "https://api-inference.modelscope.cn/v1"
env_key = "MODELSCOPE_API_KEY"
wire_api = "chat"

[profiles.modelscope]
model = "Qwen/Qwen3-Coder-480B-A35B-Instruct"
model_provider = "modelscope"
model_reasoning_effort = "high"

[model_providers.openrouter]
name = "OpenRouter"
base_url = "https://openrouter.ai/api/v1"
env_key = "OPENROUTER_API_KEY"
wire_api = "chat"

[profiles.openrouter]
#model = "openai/gpt-oss-120b:free"
#model = "moonshotai/kimi-k2:free"
#model = "qwen/qwen3-coder:free"
#model = "deepseek/deepseek-chat-v3.1:free"
model = "x-ai/grok-4-fast:free"
model_provider = "openrouter"
model_reasoning_effort = "high"

```
### 3. 运行

在 $HOME/.bashrc 中添加环境变量：

```bash
export MODELSCOPE_API_KEY="modelscope-key"
```

在命令行中直接运行：

```bash
source $HOME/.bashrc
codex
```

### 4. 一键安装脚本
为简化安装与配置流程，可下载并运行以下脚本：

```bash
curl -LO https://raw.githubusercontent.com/sim4d/blog/refs/heads/main/tools/install-codex.sh

# 查看脚本使用说明
bash ./install-codex.sh --help
```

## Claude 配置使用魔塔 API 

### 1. 安装
通过 npm 全局安装 Claude 相关工具：

```bash
npm install -g @anthropic-ai/claude-code@latest
```

### 2. 配置
手动创建并编辑 `$HOME/.claude/settings.json-mscope` 文件，填写相关配置信息。注意：把`<model-key>` 替换为实际 API Key。

```json

{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "<model-key>",
    "ANTHROPIC_BASE_URL": "https://api-inference.modelscope.cn",
    "ANTHROPIC_MODEL": "Qwen/Qwen3-Coder-480B-A35B-Instruct",
    "ANTHROPIC_SMALL_FAST_MODEL": "Qwen/Qwen3-Coder-480B-A35B-Instruct",
    "API_TIMEOUT_MS": "6000000"
  }
}

```

### 3. 运行
使用以下命令启动 Claude，指定配置文件：
```bash
claude --settings $HOME/.claude/settings.json-mscope
```

### 4. 一键安装脚本
为简化整体流程，可下载并运行以下脚本：

```bash
curl -LO https://raw.githubusercontent.com/sim4d/blog/refs/heads/main/tools/install-claude.sh

# 查看脚本使用说明
bash ./install-claude.sh --help

```

## 总结
OpenAI Codex 和 Anthropic Claude 均提供了强大的命令行编程支持。通过以上步骤，您可以快速完成安装配置使用魔塔社区提供的免费 API，魔塔账号关联阿里云账号之后，每天可以免费使用 2000 次调用。一键安装脚本进一步降低了使用门槛，适合希望快速上手的开发者。更多详细信息，请参考脚本的 `--help` 文档。
