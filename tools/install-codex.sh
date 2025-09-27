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
  cat << EOF

*******************
--- Preparations
--- show codex config example

$0 --show_example

--- Or save config example directly

export CFG=$HOME/.codex/config.toml && [ -f \$CFG ] && cp \$CFG \$CFG-\$(date +%Y%m%d-%H%M%S)
mkdir -p $HOME/.codex/ && $0 --show_example > \$CFG

*******************
--- show claude config example

$0 --show_claude

--- Or save config example directly

export CFG=$HOME/.claude/settings.json-mscope && [ -f \$CFG ] && cp \$CFG \$CFG-\$(date +%Y%m%d-%H%M%S)
mkdir -p $HOME/.claude/ && $0 --show_claude > \$CFG

*******************
--- IMPORTANT !!!
--- 1. add below env in $HOME/.bashrc

export MODELSCOPE_API_KEY="<key>"
export OPENROUTER_API_KEY="<key>"

*******************
--- Start up
run 'source ~/.bashrc' or restart your terminal to use the installed packages.
run 'codex' 

------------------------
--- Happy Coding !!! ---
------------------------

EOF
}

# --- Function to print example of config.json ---
display_example() {
  cat << EOF

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

echo -e "\n --- Installing npm v11.5.2 ---"
npm install -g npm@11.5.2

echo -e "\n--- Installing openai/codex ---"
npm install -g @openai/codex

display_help

