#!/bin/bash

# Load nvm if available (so the script works under cron's minimal environment).
# Sourcing nvm.sh alone only defines the `nvm` function; activate the default
# Node so node/npm and global bins actually land on PATH under cron.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
if command -v nvm >/dev/null 2>&1; then
    nvm use default >/dev/null 2>&1 || echo " [!] Could not activate nvm default Node — falling back to whatever npm is on PATH."
fi

MAX_RETRIES=3

# npm-manageable packages
# PACKAGES=("@anthropic-ai/claude-code" "@openai/codex" "@google/gemini-cli" "@qwen-code/qwen-code" "@qoder-ai/qodercli")
PACKAGES=("@anthropic-ai/claude-code" "@openai/codex" "@moonshot-ai/kimi-code" "@deepseek-ai/dsh" "@deepseek-harness-tui/dsh-tui")

# Resolve binary name for a package (basename is wrong for some scoped packages).
# IMPORTANT: When adding a new package to PACKAGES, also add it here.
get_bin_name() {
    case "$1" in
        @anthropic-ai/claude-code) echo "claude" ;;
        @openai/codex)             echo "codex" ;;
        @qoder-ai/qodercli)       echo "qodercli" ;;
        @moonshot-ai/kimi-code)   echo "kimi" ;;
        @deepseek-ai/dsh)         echo "dsh" ;;
        @deepseek-harness-tui/dsh-tui) echo "dsh-tui" ;;
        *)                         basename "$1" ;;
    esac
}

# npm install with retry on network failure
npm_install_with_retry() {
    local pkg="$1"
    local attempt=1
    NPM_INSTALL_OK=1

    while [ "$attempt" -le "$MAX_RETRIES" ]; do
        echo " -> npm install attempt $attempt/$MAX_RETRIES..."
        if npm install -g "$pkg" 2>&1; then
            NPM_INSTALL_OK=0
            return 0
        fi
        echo " [!] npm install failed (attempt $attempt). Retrying in $((attempt * 5))s..."
        sleep $((attempt * 5))
        attempt=$((attempt + 1))
    done

    echo " [!] All $MAX_RETRIES npm install attempts failed for $pkg."
    NPM_INSTALL_OK=1
    return 1
}

# Verify the CLI binary works. If not, retry install + postinstall to
# repair a missing native binary (can happen when the CLI is running
# during upgrade — npm silently skips optional dependencies).
verify_cli_binary() {
    local pkg="$1"
    local bin_name

    bin_name=$(get_bin_name "$pkg")

    if command -v "$bin_name" >/dev/null 2>&1 && "$bin_name" --version >/dev/null 2>&1; then
        echo " [✓] Verified: $bin_name --version OK"
        VERIFY_OK=0
        return 0
    fi

    echo " [!] $bin_name health check FAILED — likely missing native binary."

    # Retry install (the CLI process may have exited by now)
    npm_install_with_retry "$pkg"
    if [ "$NPM_INSTALL_OK" -eq 0 ] && "$bin_name" --version >/dev/null 2>&1; then
        echo " [✓] Reinstall succeeded: $bin_name --version OK"
        VERIFY_OK=0
        return 0
    fi

    # Try the package's own install/postinstall script directly (re-fetches
    # just the native binary). The file name differs per package
    # (install.cjs / install.js / ...), so probe the known candidates and
    # fall back to npm's lifecycle runner for anything else.
    pkg_dir="$(npm root -g 2>/dev/null)/$pkg"
    repair_script=""
    for candidate in "$pkg_dir/install.cjs" "$pkg_dir/install.js" "$pkg_dir/postinstall.js"; do
        if [ -f "$candidate" ]; then
            repair_script="$candidate"
            break
        fi
    done
    if [ -n "$repair_script" ]; then
        echo " -> Running postinstall script manually: $(basename "$repair_script")"
        node "$repair_script" 2>&1
    elif [ -d "$pkg_dir" ]; then
        echo " -> Re-running install lifecycle scripts via npm..."
        (cd "$pkg_dir" && npm run postinstall --if-present) 2>&1
    fi
    if "$bin_name" --version >/dev/null 2>&1; then
        echo " [✓] Postinstall repair succeeded: $bin_name --version OK"
        VERIFY_OK=0
        return 0
    fi

    # Last resort: uninstall + reinstall
    echo " -> Attempting clean reinstall..."
    npm uninstall -g "$pkg" 2>&1
    npm_install_with_retry "$pkg"
    if [ "$NPM_INSTALL_OK" -eq 0 ] && "$bin_name" --version >/dev/null 2>&1; then
        echo " [✓] Clean reinstall succeeded: $bin_name --version OK"
        VERIFY_OK=0
        return 0
    fi

    echo " [✗] FAILED to verify $bin_name — tomorrow's cron will retry."
    VERIFY_OK=1
    return 1
}

# ---- Main ------------------------------------------------------------------

echo "=== npm packages: ${PACKAGES[*]} ==="

# Update Antigravity CLI first
AGY_BIN="$HOME/.local/bin/agy"
echo "=== Antigravity CLI (agy) ==="
echo "----------------------------------------------------"
if [ ! -f "$AGY_BIN" ]; then
    echo " [!] Antigravity CLI is not installed."
    echo " -> Installing via curl..."
    if (set -o pipefail; curl -fsSL --max-time 120 --retry 2 https://antigravity.google/cli/install.sh | bash); then
        echo " [✓] Antigravity CLI installed."
    else
        echo " [!] Antigravity CLI install failed (curl or installer returned non-zero)."
    fi
else
    INSTALLED_VERSION=$("$AGY_BIN" --version 2>/dev/null | head -1)
    echo " Current version: $INSTALLED_VERSION"
    echo " Note: Antigravity CLI auto-updates in the background."
    echo " Running $AGY_BIN update"
    "$AGY_BIN" update
fi

INSTALLED_LIST=$(npm list -g --depth=0 2>/dev/null)

for PACKAGE in "${PACKAGES[@]}"; do
    echo "----------------------------------------------------"
    echo "Checking $PACKAGE..."

    BIN_NAME=$(get_bin_name "$PACKAGE")

    INSTALLED_VERSION=$(echo "$INSTALLED_LIST" | grep -F "$PACKAGE@" | awk -F@ '{print $NF}' | head -1)
    if [ -z "$INSTALLED_VERSION" ]; then
        echo " [!] $PACKAGE is not installed."
        echo " -> Installing..."
        npm_install_with_retry "$PACKAGE"
        if [ "$NPM_INSTALL_OK" -eq 0 ]; then
            verify_cli_binary "$PACKAGE"
        fi
        continue
    fi

    echo " Current version: $INSTALLED_VERSION"

    LATEST_VERSION=$(npm view "$PACKAGE" version 2>/dev/null)
    if [ -z "$LATEST_VERSION" ]; then
        echo " [!] Could not fetch latest version for $PACKAGE."
        continue
    fi

    echo " Latest version:  $LATEST_VERSION"

    NEEDS_UPDATE=0
    if [ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]; then
        if [ "$(printf '%s\n' "$INSTALLED_VERSION" "$LATEST_VERSION" | sort -V | head -n1)" = "$INSTALLED_VERSION" ]; then
            echo " -> Update available. Upgrading $PACKAGE..."
            NEEDS_UPDATE=1
        else
            echo " -> Installed version seems newer or same (sanity check)."
        fi
    else
        echo " -> Up to date."
    fi

    if [ "$NEEDS_UPDATE" -eq 1 ]; then
        npm_install_with_retry "$PACKAGE"
        if [ "$NPM_INSTALL_OK" -eq 0 ]; then
            verify_cli_binary "$PACKAGE"
        fi
    else
        # Even if up to date, verify the binary works — a previous
        # install may have silently skipped the native binary.
        verify_cli_binary "$PACKAGE"
    fi
done

echo ""
echo "=== Final health check summary ==="
FAILED_CLIS=()
for PACKAGE in "${PACKAGES[@]}"; do
    BIN_NAME=$(get_bin_name "$PACKAGE")
    if command -v "$BIN_NAME" >/dev/null 2>&1 && "$BIN_NAME" --version >/dev/null 2>&1; then
        VERSION=$("$BIN_NAME" --version 2>/dev/null | head -1)
        echo " [✓] $BIN_NAME: $VERSION"
    else
        echo " [✗] $BIN_NAME: BROKEN"
        FAILED_CLIS+=("$BIN_NAME")
    fi
done

if [ "${#FAILED_CLIS[@]}" -gt 0 ]; then
    echo ""
    echo " [!] The following CLIs failed verification: ${FAILED_CLIS[*]}"
    echo " [!] If a CLI process was running during upgrade, tomorrow's cron will retry."
    # Non-zero exit so cron/CI can detect a failed nightly update.
    exit 1
fi

echo ""
# (END)
