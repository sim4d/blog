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
--- show config example

$0 --show_example

--- Or save config example directly

export CFG=$HOME/.claude/settings.json-mscope && [ -f \$CFG ] && cp \$CFG \$CFG-\$(date +%Y%m%d-%H%M%S)
mkdir -p $HOME/.claude/ && $0 --show_example > \$CFG

*******************
--- IMPORTANT !!!
--- replace "ANTHROPIC_AUTH_TOKEN" with real key

vi $HOME/.claude/settings.json-mscope

*******************
--- Start up

claude --settings ~/.claude/settings.json-mscope

------------------------
--- Happy Coding !!! ---
------------------------

EOF
}

# --- Function to print example of config.json ---
display_example() {
  cat << EOF

{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "<key>",
    "ANTHROPIC_BASE_URL": "https://api-inference.modelscope.cn",
    "ANTHROPIC_MODEL": "Qwen/Qwen3-Coder-480B-A35B-Instruct",
    "ANTHROPIC_SMALL_FAST_MODEL": "Qwen/Qwen3-Coder-480B-A35B-Instruct",
    "API_TIMEOUT_MS": "3000000"
  }
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

echo -e "\n --- Installing npm v11.5.2 ---"
npm install -g npm@11.5.2

echo -e "\n --- Installing Claude Code ---"
npm install -g @anthropic-ai/claude-code@latest

display_help

