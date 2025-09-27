---
layout: post  
title: "Claude Code via CCR 深度使用：配置篇"  
toc: true
categories:
  - AI
  - Programming
tags:
  - Claude Code
  - CCR
---

Claude Code 正以「程序员终极助手」的身份走红 —— 许多工程师在深度试用过 Cursor 等热门工具后，纷纷转向 Claude Code。凭借更强的上下文理解能力和代码生成精准度，它成了开发者眼中「能扛事、少踩坑」的新选择。

---

## 安装 Claude Code

开始之前，先复习一下安装 Claude Code 的最稳妥的方式，此方式适合 WSL + Ubuntu 环境，或者直接 Linux 虚机。

安装nvm

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

source ~/.bashrc
```

使用 lts 版本的 node

```bash
nvm install --lts

nvm use --lts
```

### 安装 v11.5.2 的 npm，重要 !!!

```bash
npm install -g npm@v11.5.2
```

好了，可以安装 cc 了

```bash
npm install -g @anthropic-ai/claude-code
```

安装 ccr

```bash
npm install -g @musistudio/claude-code-router@latest
```

安装配置小工具

```bash
npm install @leason/claude-code-config -g
```

---

## 配置使用 魔塔社区 API

1. 魔搭社区地址 https://modelscope.cn/my/overview
   注册
2. 账号设置：https://modelscope.cn/my/accountsettings
   绑定阿里云账号，重要！！！
3. 创建令牌：https://modelscope.cn/my/myaccesstoken
   有效期选择 “长期有效”

#### 注意：魔塔社区账号要关联 阿里云账号，才能获得每天 2000 次的免费使用量，重要 ！！！

4. 运行配置小工具，填入魔塔社区获取的 API Key

```bash
ccr-modelscope
```

---

## 配置使用 qwen-cli

这里说对接 qwen-cli 步骤：

1. 安装qwen-cli（ https://github.com/QwenLM/qwen-code ）

```bash
npm install -g @qwen-code/qwen-code@latest
qwen --version
```

### 登录 qwen-cli，选择 qwen Oauth 登录，走完登录流程，重要 !!!

```bash
qwen
```
### 将来也要定期登录 qwen-cli，确保命令行能正常工作

在对应的provider，增加qwen-cli的设置项，api\_key随意填

```json
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

```json
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

```json
{
  "LOG": false,
  "CLAUDE_PATH": "",
  "HOST": "127.0.0.1",
  "PORT": 3456,
  "APIKEY": "",
  "API_TIMEOUT_MS": "600000",
  "PROXY_URL": "",
  "transformers": [
    {
      "path": "/home/user/.claude-code-router/plugins/qwen-cli.js"
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

## CCR UI

ccr 支持 ui 配置，用 ccr ui 启动就可以界面配置，切换不同 Providers

```bash
ccr ui
```

注意设置保存后，需要在命令行重启 ccr 

```bash
ccr restart
```

启动

```bash
ccr code
```

或者直接学习高手的用法，后果自负 :)

```bash
ccr code --dangerously-skip-permissions
```

## 一键安装脚本 install-all.sh

为方便安装，可以下载 `install-all.sh` ，一键安装这篇文章所讨论的各个模块。

```bash

curl -o $HOME/install-all.sh https://raw.githubusercontent.com/sim4d/blog/refs/heads/main/tools/install-all.sh
chmod +x $HOME/install-all.sh
$HOME/install-all.sh --help
$HOME/install-all.sh

```

#### 注：本脚本在 Ubuntu，WSL + Ubuntu 下测试通过。
#### 脚本1:
curl -LO https://raw.githubusercontent.com/sim4d/blog/refs/heads/main/tools/install-all.sh
#### 脚本2：安装CLI
curl -LO https://raw.githubusercontent.com/sim4d/blog/refs/heads/main/tools/install-cli.sh
