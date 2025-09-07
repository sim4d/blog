#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Function to install extension components ---
install_ext() {
  echo -e "\n--- Installing gemini-cli ---"
  npm install -g @google/gemini-cli@latest

  echo -e "\n--- Installing rovodev-cli ---"
  npm install -g rovodev@latest

  echo -e "\n--- Downloading CCR plugins ---"
  mkdir -p "$HOME/.claude-code-router/plugins"
  curl -o "$HOME/.claude-code-router/plugins/gemini-cli.js" https://gist.githubusercontent.com/musistudio/1c13a65f35916a7ab690649d3df8d1cd/raw/9d9a627783990a602d8a887c02dba0ba507e6339/gemini-cli.js
  curl -o "$HOME/.claude-code-router/plugins/rovo-cli.js" https://gist.githubusercontent.com/SaseQ/c2a20a38b11276537ec5332d1f7a5e53/raw/8d919f7102324ba2243105c2c0bd6ffa4b396091/rovo-cli.js

  echo -e "\n--- Extension installation complete ---"
}

# --- Function to print out new section separator ---
new_section() {
  echo -e "\n\n******************************"
  echo "++++++++++++++++++++++++++++++"
  echo -e "******************************\n\n"
}

# --- Function to print help ---
display_help() {
  new_section
  echo "--- Preparations ---"
  echo "-------------------"
  echo "--- 1. 获取魔塔 API key ---"
  echo "--- 注册账号 ---"
  echo "- Goto https://modelscope.cn/my/overview ---"
  echo "--- 绑定阿里云账号 ---"
  echo "- Goto https://modelscope.cn/my/accountsettings ---"
  echo "--- 新建令牌，选择“长期有效” ---"
  echo "- Goto https://modelscope.cn/my/myaccesstoken ---"
  echo "-------------------"
  echo "--- 2. 登录 qwen-cli ---"
  echo "--- 登录 qwen-cli，选择 qwen Oauth 登录，走完登录流程 ---"
  echo "-------------------"
  echo "--- 3. 显示 config.json 示例 ---"
  echo "--- $ ./install-all.sh --show_example"
  echo "- Or ------------------"
  echo '--- $ CFG=$HOME/.claude-code-router/config.json && [ -f $CFG ] && cp $CFG $CFG-$(date +%Y%m%d-%H%M%S)'
  echo '--- $ mkdir -p $HOME/.claude-code-router/ && ./install-all.sh --show_example >$HOME/.claude-code-router/config.json'
  echo "-------------------"
  echo "--- 4. 编辑/修改 魔塔 API ---"
  echo "-------------------"
  echo "--- 5. 运行 ---"
  echo "Please run 'source ~/.bashrc' or restart your terminal to use the installed packages."
  echo "run 'ccr ui' to check and/or change default provider"
  echo "run 'ccr restart' to take effect with new configuration"
  echo "run 'ccr code' to start."
  echo "-------------------"
  echo "--- Happy Coding !!! ---"
  echo
}

# --- Function to print example of config.json ---
display_example() {
  cat << EOF

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
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

echo -e "\n --- Sourcing nvm ---"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

echo -e "\n --- Installing and using LTS version of Node.js ---"
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'

echo -e "\n --- Installing npm v11.5.2 ---"
npm install -g npm@11.5.2

echo -e "\n --- Installing Claude Code ---"
npm install -g @anthropic-ai/claude-code@latest

echo -e "\n --- Installing claude-code-router ---"
npm install -g @musistudio/claude-code-router@latest

echo -e "\n --- Installing claude-code-config ---"
npm install -g @leason/claude-code-config@latest

echo -e "\n --- Installing qwen-code ---"
npm install -g @qwen-code/qwen-code@latest

echo -e "\n --- Downloading CCR plugins ---"
mkdir -p "$HOME/.claude-code-router/plugins"
curl -o "$HOME/.claude-code-router/plugins/qwen-cli.js" https://gist.githubusercontent.com/musistudio/f5a67841ced39912fd99e42200d5ca8b/raw/ca2b5132cbcca5ed558569364e45085732446908/qwen-cli.js

# --- Check for --ext flag ---
if [ "$1" == "--ext" ]; then
  install_ext
fi

display_help

