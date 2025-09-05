#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Function to install extension components ---
install_ext() {
  echo "--- Installing gemini-cli ---"
  npm install -g @google/gemini-cli@latest

  echo "--- Installing rovodev-cli ---"
  npm install -g rovodev@latest

  echo "--- Downloading CCR plugins ---"
  mkdir -p "$HOME/.claude-code-router/plugins"
  curl -o "$HOME/.claude-code-router/plugins/gemini-cli.js" https://gist.githubusercontent.com/musistudio/1c13a65f35916a7ab690649d3df8d1cd/raw/9d9a627783990a602d8a887c02dba0ba507e6339/gemini-cli.js
  curl -o "$HOME/.claude-code-router/plugins/rovo-cli.js" https://gist.githubusercontent.com/SaseQ/c2a20a38b11276537ec5332d1f7a5e53/raw/8d919f7102324ba2243105c2c0bd6ffa4b396091/rovo-cli.js

  echo "--- Extension installation complete ---"
}

# --- Main installation process (default) ---
echo "--- Installing nvm ---"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

echo "--- Sourcing nvm ---"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

echo "--- Installing and using LTS version of Node.js ---"
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'

echo "--- Installing npm v11.5.2 ---"
npm install -g npm@11.5.2

echo "--- Installing Claude Code ---"
npm install -g @anthropic-ai/claude-code@latest

echo "--- Installing claude-code-router ---"
npm install -g @musistudio/claude-code-router@latest

echo "--- Installing claude-code-config ---"
npm install -g @leason/claude-code-config@latest

echo "--- Installing qwen-code ---"
npm install -g @qwen-code/qwen-code@latest

# --- Check for --ext flag ---
if [ "$1" == "--ext" ]; then
  install_ext
fi

echo "--- Installation complete ---"
echo "Please run 'source ~/.bashrc' or restart your terminal to use the installed packages."
