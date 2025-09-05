---
title: Claude Code via CCR 深度使用：配置篇（二）
date: 2025-08-28 22:34:20 +0800
toc: true
categories: [AI, Programming]
tags: [Claude Code, CCR]
---

# Claude Code via CCR: Configure Part II

在上一篇文章《Claude Code via CCR: 配置篇（一）》中，我们介绍了如何通过 CCR（Claude Code Router）配置并使用目前公认最强的 Agentic Coding 工具——Claude Code。近期，CCR 新版本新增了对 Gemini-CLI 和 Rovodev API 的支持。本文将详细介绍这两者的具体配置步骤，并在文末以表格形式总结当前各渠道的每日免费使用额度，方便大家参考。

若因排版问题导致脚本 / 配置无法复制，可点击页末 “阅读原文”，或通过下方链接在浏览器中打开查看并拷贝。

https://sim4ai.com/2025/08/claude-code-via-ccr-config2/

## 1. Gemini CLI 配置

Gemini CLI 的配置方式与 Qwen CLI 类似，操作简单。首先，下载 `gemini-cli.js` 文件，并将其保存至 `$HOME/.claude-code-router/plugins/gemini-cli.js`。随后，在 `$HOME/.claude-code-router/config.json` 中添加相关配置。需要注意以下几点：  

- 确保 `gemini` 命令行工具已安装，并通过 OAuth 认证，能正常运行。  
- 在 `config.json` 中正确配置 `PROXY_URL` 字段。
- 在 `config.json` 中正确配置 `google-cloud-project-id` 字段。

**下载路径：**  

```javascript
// 下载 gemini-cli.js
https://gist.githubusercontent.com/musistudio/1c13a65f35916a7ab690649d3df8d1cd/raw/9d9a627783990a602d8a887c02dba0ba507e6339/gemini-cli.js
```

**config.json 配置示例：**  

```json
{
  "PROXY_URL": "http://127.0.0.1:pppp",
  "transformers": [
    {
      "path": "/home/user/.claude-code-router/plugins/gemini-cli.js",
      "options": {
        "project": "your-google-cloud-project-id"
      }
    }
  ],
  "Providers": [
    {
      "name": "gemini-cli",
      "api_base_url": "(idk)",
      "api_key": "not-required",
      "models": ["gemini-2.5-pro"],
      "transformer": {
        "use": ["gemini-cli"]
      }
    }
  ],
  "Router": {
    "default": "gemini-cli,gemini-2.5-pro"
  }
}
```

## 2. Rovodev API 配置

Rovodev API 的配置流程同样直观。首先，下载 `rovo-cli.js` 文件，保存至 `$HOME/.claude-code-router/plugins/rovo-cli.js`。然后，更新 `$HOME/.claude-code-router/config.json`，添加相关配置。注意事项如下：  

- 确保 `acli rovodev run` 命令行工具已安装，并能正常启动运行。  
- 在 `config.json` 中正确填写 `ROVO_DEV_EMAIL` 和 `ROVO_DEV_API_TOKEN` 字段。

**下载路径：**  

```javascript
// 下载 rovo-cli.js
https://gist.githubusercontent.com/SaseQ/c2a20a38b11276537ec5332d1f7a5e53/raw/8d919f7102324ba2243105c2c0bd6ffa4b396091/rovo-cli.js
```

**config.json 配置示例：**  

```json
{
  "transformers": [
    {
      "path": "/home/user/.claude-code-router/plugins/rovo-cli.js",
      "options": {
        "email": "ROVO_DEV_EMAIL",
        "api_token": "ROVO_DEV_API_TOKEN"
      }
    }
  ],
  "Providers": [
    {
      "name": "rovo-cli",
      "api_base_url": "https://api.atlassian.com/rovodev/v2/proxy/ai/v1/openai/v1/chat/completions",
      "api_key": "sk-xxx",
      "models": ["gpt-5-2025-08-07"],
      "transformer": {
        "use": ["rovo-cli"]
      }
    }
  ],
  "Router": {
    "default": "rovo-cli,gpt-5-2025-08-07"
  }
}
```

## 3. 每日免费额度总结

以下表格总结了当前各 API 的每日免费使用额度，供大家快速对比参考：

| **API 名称**      | **每日免费额度** | **其它说明**             |
| ----------------- | ---------------- | ------------------------ |
| Qwen + 魔塔 API   | 2000 次          | 魔塔账号需关联阿里云账户 |
| Qwen CLI          | 2000 次          |                          |
| Qwen + OpenRouter | 1000 次          | 账户余额大于 10USD       |
| Gemini CLI        | 1000 次          | 配置 PROXY_URL           |
| Rovo CLI          | 5M tokens        |                          |

*注：具体额度可能随官方政策调整，请以实际使用时查询为准。*

## 4. 完整 config.json 配置示例

为方便整合，以下是一个完整的 `config.json` 配置示例，包含这两篇文章所讨论的各 API 的设置：

```json
{
  "LOG": false,
  "CLAUDE_PATH": "",
  "HOST": "127.0.0.1",
  "PORT": 3456,
  "APIKEY": "",
  "API_TIMEOUT_MS": "600000",
  "PROXY_URL": "http://127.0.0.1:pppp",
  "transformers": [
    {
      "path": "/home/user/.claude-code-router/plugins/qwen-cli.js",
    },
    {
      "path": "/home/user/.claude-code-router/plugins/gemini-cli.js",
      "options": {
        "project": "your-google-cloud-project-id"
      }
    },
    {
      "path": "/home/user/.claude-code-router/plugins/rovo-cli.js",
      "options": {
        "email": "ROVO_DEV_EMAIL",
        "api_token": "ROVO_DEV_API_TOKEN"
      }
    }
  ],
"Providers": [
  {
    {
      "name": "modelscope",
      "api_base_url": "https://api-inference.modelscope.cn/v1/chat/completions",
      "api_key": "<your-api-key>",
      "models": [
        "Qwen/Qwen3-Coder-480B-A35B-Instruct"
      ],
      "transformer": {
        "use": [
          [
            "maxtoken",
            {
              "max_tokens": 65536
            }
          ]
        ]
      }
    },
    {
      "name": "qwen-cli",
      "api_base_url": "https://portal.qwen.ai/v1/chat/completions",
      "api_key": "not-required",
      "models": [
        "qwen3-coder-plus"
      ],
      "transformer": {
        "use": [
          "qwen-cli",
          "enhancetool"
        ]
      }
    },
    {
      "name": "openrouter",
      "api_base_url": "https://openrouter.ai/api/v1/chat/completions",
      "api_key": "<your-api-key>",
      "models": [
        "qwen/qwen3-coder:free"
      ],
      "transformer": {
        "use": [ "openrouter" ]
      }
    },
    {
      "name": "gemini-cli",
      "api_base_url": "(not-required)",
      "api_key": "not-required",
      "models": ["gemini-2.5-pro"],
      "transformer": {
        "use": ["gemini-cli"]
      }
    },
    {
      "name": "rovo-cli",
      "api_base_url": "https://api.atlassian.com/rovodev/v2/proxy/ai/v1/openai/v1/chat/completions",
      "api_key": "not-required",
      "models": ["gpt-5-2025-08-07"],
      "transformer": {
        "use": ["rovo-cli"]
      }
    }
  ],
  "Router": {
    "default": "qwen-cli,qwen3-coder-plus",
    "background": "",
    "think": "",
    "longContext": "",
    "longContextThreshold": 60000,
    "webSearch": ""
  },
  "stream": false
}
```