#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Function to print out new section separator ---
new_section() {
  echo -e "\n\n******************************"
  echo "++++++++++++++++++++++++++++++"
  echo -e "******************************\n\n"
}

# --- Function to print help ---
display_help() {
  new_section
  cat << EOF

--- Preparations ---
-------------------
--- 1. 登录 qwen-cli ---
--- 登录 qwen-cli，选择 Oauth 登录，走完登录流程 ---
-------------------
--- 2. 登录 gemini-cli ---
--- 登录 gemini-cli，选择 Oauth 登录，走完登录流程 ---
-------------------
--- 3. 登录 rovodev-cli ---
- goto https://support.atlassian.com/rovo/docs/install-and-run-rovo-dev-cli-on-your-device/ , and deploy rovodev cli
--- 登录 acli rovodev ，输入邮件和密文，走完登录流程 ---
-------------------
--- 4. 显示 config.json 示例 ---
--- $ $0 --show_example
- Or ------------------
export CFG=$HOME/.claude-code-router/config.json && [ -f \$CFG ] && cp \$CFG \$CFG-\$(date +%Y%m%d-%H%M%S)
mkdir -p $HOME/.claude-code-router/ && $0 --show_example > \$CFG
-------------------
--- 5. IMPORTANT !!!
-- 5.1 change ALL transformers.path in $HOME/.claude-code-router/config.json with actual \$HOME path
-- 5.2 add PROXY_URL: "" if needed ---
-- 5.3 rovodev: add email and credential string ---
-- 5.4 gemini: add transformers.options.project with Google Vertex project-id
-------------------
--- 6. Start up ---
Please run 'source ~/.bashrc' or restart your terminal to use the installed packages.
run 'ccr ui' to check and/or change default provider
run 'ccr restart' to take effect with new configuration
run 'ccr code' to start.

------------------------
--- Happy coding! 🚀
------------------------

EOF
}

# --- Function to print example of config.json ---
display_example() {
  cat << EOF

{
  "LOG": false,
  "LOG_LEVEL": "debug",
  "CLAUDE_PATH": "",
  "HOST": "127.0.0.1",
  "PORT": 3456,
  "APIKEY": "",
  "API_TIMEOUT_MS": "600000",
  "PROXY_URL": "",
  "transformers": [
    {
      "path": "$HOME/.claude-code-router/plugins/qwen-cli.js"
    },
    {
      "path": "$HOME/.claude-code-router/plugins/gemini-cli.js",
      "options": {
        "project": "your-google-cloud-project-id"
      }
    },
    {
      "path": "$HOME/.claude-code-router/plugins/rovo-cli.js",
      "options": {
        "email": "ROVO_DEV_EMAIL",
        "api_token": "ROVO_DEV_API_TOKEN"
      }
    }
  ],
  "Providers": [
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
      "name": "gemini-cli",
      "api_base_url": "(not-required)",
      "api_key": "not-required",
      "models": [
        "gemini-2.5-pro"
      ],
      "transformer": {
        "use": [
          "gemini-cli"
        ]
      }
    },
    {
      "name": "rovo-cli",
      "api_base_url": "https://api.atlassian.com/rovodev/v2/proxy/ai/v1/openai/v1/chat/completions",
      "api_key": "not-required",
      "models": [
        "gpt-5-2025-08-07"
      ],
      "transformer": {
        "use": [
          "rovo-cli"
        ]
      }
    }
  ],
  "StatusLine": {
    "enabled": false,
    "currentStyle": "default",
    "default": {
      "modules": []
    },
    "powerline": {
      "modules": []
    }
  },
  "Router": {
    "default": "qwen-cli,qwen3-coder-plus",
    "background": "",
    "think": "",
    "longContext": "",
    "longContextThreshold": 60000,
    "webSearch": "",
    "image": ""
  },
  "CUSTOM_ROUTER_PATH": ""
}

EOF
}


# --- Check for -- flag ---
if [ "$1" == "--show_example" ]; then
  display_example
  exit 0
fi

# --- Check for -- flag ---
if [ "$1" == "--help" ]; then
  display_help
  exit 0
fi

# --- Main installation process (default) ---
new_section
echo "--- Installing nvm ---"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

echo -e "\n --- Sourcing nvm ---"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

echo -e "\n --- Installing and using LTS version of Node.js ---"
nvm install --lts
nvm alias default 'lts/*'
nvm use --lts

echo -e "\n --- Installing npm v11.6.2 ---"
npm install -g npm@11.6.2

echo -e "\n --- Installing Claude Code ---"
npm install -g @anthropic-ai/claude-code@latest

echo -e "\n --- Installing claude-code-router ---"
npm install -g @musistudio/claude-code-router@latest

echo -e "\n --- Installing claude-code-config ---"
npm install -g @leason/claude-code-config@latest

echo -e "\n --- Installing qwen-code ---"
npm install -g @qwen-code/qwen-code@latest

echo -e "\n--- Installing gemini-cli ---"
npm install -g @google/gemini-cli@latest

echo -e "\n--- Installing openai/codex ---"
npm install -g @openai/codex

echo -e "\n--- Installing cursor-agent ---"
curl https://cursor.com/install -fsS | bash

echo -e "\n--- Installing qoder cli---"
curl -fsSL https://qoder.com/install | bash

echo -e "\n--- Installing iflow cli---"
npm install -g @iflow-ai/iflow-cli

echo -e "\n--- Installing kilocode cli---"
npm install -g @kilocode/cli

echo -e "\n--- Installing rovodev-cli ---"
curl -LO "https://acli.atlassian.com/linux/latest/acli_linux_amd64/acli" && chmod +x ./acli && mkdir -p ~/.local/bin && mv ./acli ~/.local/bin/acli

echo "append (or prepend) ~/.local/bin to \$PATH"
echo "goto https://support.atlassian.com/rovo/docs/install-and-run-rovo-dev-cli-on-your-device/ , and register and obtain credential"

echo -e "\n--- Installing codebuddy-code ---"
npm install -g @tencent-ai/codebuddy-code

echo -e "\n --- Downloading CCR plugins ---"

mkdir -p "$HOME/.claude-code-router/plugins"
curl -o "$HOME/.claude-code-router/plugins/qwen-cli.js" https://gist.githubusercontent.com/musistudio/f5a67841ced39912fd99e42200d5ca8b/raw/ca2b5132cbcca5ed558569364e45085732446908/qwen-cli.js

curl -o "$HOME/.claude-code-router/plugins/gemini-cli.js" https://gist.githubusercontent.com/musistudio/1c13a65f35916a7ab690649d3df8d1cd/raw/9d9a627783990a602d8a887c02dba0ba507e6339/gemini-cli.js
curl -o "$HOME/.claude-code-router/plugins/rovo-cli.js" https://gist.githubusercontent.com/SaseQ/c2a20a38b11276537ec5332d1f7a5e53/raw/8d919f7102324ba2243105c2c0bd6ffa4b396091/rovo-cli.js

display_help

