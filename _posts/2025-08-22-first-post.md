---
layout: post  
title: "Claude Code via CCR 深度使用"  
toc: true
---

情况就是这么个情况：

1. qwen-cli 每天免费提供 2000次 的 qwen3-coder-plus
2. 魔搭社区每天免费提供 2000 次的 qwen3-coder
3. 不是所有人都想用 qwen-cli（原因不重要），想用 claude code
4. 于是有人想用 claude code，但是白嫖 qwen 的模型
5. 很多人习惯了claude code，然后模型各种更新，拥抱 claude code 30 秒不动摇

---

## 安装 Claude Code

开始之前，先复习一下安装 Claude Code 的最稳妥的方式，此方式适合 WSL + Ubuntu 环境，或者直接 Ubuntu Linux 虚机。

安装nvm

```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

source ~/.bashrc
```

使用 lts 版本的 node

```
nvm install --lts

nvm use --lts
```

### 安装 v11.5.2 的 npm，重要 !!!

```
npm install -g npm@v11.5.2
```

好了，可以安装 ccr 了

```
npm install -g @musistudio/claude-code-router@latest
```

下载配置小工具

```
npm install @leason/claude-code-config -g
```

---

## 配置使用 魔塔社区 API

魔搭社区地址 https://modelscope.cn/my/overview

### 注意：魔塔社区账号要关联 阿里云账号，才能获得每天 2000 次的免费使用量，重要 ！！！

运行配置小工具，填入魔塔社区获取的 API Key

```
ccr-modelscope
```

---

## 配置使用 qwen-cli

魔搭怎么用就不说了，这里说对接qwen-cli，步骤：

1. 安装qwen-cli（ https://github.com/QwenLM/qwen-code ）

```
npm install -g @qwen-code/qwen-code@latest
qwen --version
```

### 登录 qwen-cli，选择 qwen Oauth 登录，走完登录流程，重要 !!!

```
qwen
```

在对应的provider，增加qwen-cli的设置项，api\_key随意填

```
    {
      "name": "qwen-cli",
      "api_base_url": "https://portal.qwen.ai/v1/chat/completions",
      "api_key": "sk-xxxx",
      "models": [
        "qwen3-coder-plus"
      ],
      "transformer": {
        "use": [
          "qwen-cli",
          "enhancetool"
        ]
      }
    }
```

在 router 部分配置使用这个模型（仅使用qwen-cli）

```
    "Router": {
        "default": "qwen-cli,qwen3-coder-plus",
        "background": "",
        "think": "",
        "longContext": "",
        "longContextThreshold": 60000,
        "webSearch": ""
    }
```

---

我这个混合使用 qwen 和 modelscope，配好就这个样子

```
{
  "LOG": false,
  "CLAUDE_PATH": "",
  "HOST": "127.0.0.1",
  "PORT": 3456,
  "APIKEY": "",
  "API_TIMEOUT_MS": "600000",
  "PROXY_URL": "",
  "Providers": [
    {
      "name": "qwen-cli",
      "api_base_url": "https://portal.qwen.ai/v1/chat/completions",
      "api_key": "sk-xxxx",
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
      "name": "gemini",
      "api_base_url": "https://generativelanguage.googleapis.com/v1beta/models/",
      "api_key": "<your-api-key>",
      "models": [
        "gemini-2.5-flash",
        "gemini-2.5-pro"
      ],
      "transformer": {
        "use": [
          "gemini"
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
        "use": [
          "openrouter"
        ]
      }
    },
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

---

ccr 支持 ui 配置，用 ccr ui 启动就可以界面配置，切换不同 Providers

```
ccr ui
```

注意设置保存后，需要在命令行重启 ccr ，然后能用了

```
ccr restart
```

注意设置保存后，需要在命令行重启 ccr ，然后能用了

```
ccr code
```

或者直接学习高手的用法，后果自负 :)

```
ccr code --dangerously-skip-permissions
```