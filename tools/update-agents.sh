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

# dsh-code global/profile parity signal. Tri-state, set by sync_dsh_code_profile:
#   0 = confirmed parity (global == profile resolved version)
#   1 = skew detected (pin attempted but did not converge)
#   2 = unverified (default; sync skipped, e.g. `npm view` failed or global missing)
# The final summary distinguishes these: only state 1 is a hard failure; state 2
# is a non-fatal warning so a transient registry hiccup can't force a false
# "skew" exit like the original single boolean did.
DSH_CODE_PARITY_STATE=2

# npm-manageable packages
# PACKAGES=("@anthropic-ai/claude-code" "@openai/codex" "@google/gemini-cli" "@qwen-code/qwen-code" "@qoder-ai/qodercli")
PACKAGES=("@anthropic-ai/claude-code" "@openai/codex" "@moonshot-ai/kimi-code" "@deepseek-ai/dsh" "@deepseek-harness-tui/dsh-tui" "dsh-code")

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
        dsh-code)                    echo "dsh-code" ;;
        *)                         basename "$1" ;;
    esac
}

# ---------------------------------------------------------------------------
# dsh-code version-parity sync.
#
# `dsh-code` is a global alias for `dsh --profile cli`, but its runtime is
# composed from TWO copies that MUST stay at the same version:
#
#   * the cordis patch layer (which disables host-plane tools/skills in favor
#     of per-session agent presets) is read from the GLOBAL install — the dsh
#     installation anchor wins bundle resolution (resolveBundleDir);
#   * the TUI runner that re-mounts those presets is read from the PROFILE's
#     own node_modules (the loader's baseUrl is the profile directory).
#
# If they skew, every session boots with zero tools and zero skills while
# `dsh-code --version` still exits 0 — it only exercises the launcher's
# profile-mount check, never the composed tree — so the generic binary health
# check can never catch this failure. Keep the profile runner pinned to the
# exact version of the global install.
# ---------------------------------------------------------------------------
# Read a package.json's `version` field safely: a missing file, malformed
# JSON, or a missing `version` key all yield empty (a bare `require().version`
# would otherwise print the literal string "undefined").
read_pkg_version() {
    node -e 'const v=require(process.argv[1]).version;process.stdout.write(typeof v==="string"?v:"")' "$1" 2>/dev/null
}

# Read the profile manifest's `dsh-code` dependency SPEC (may be exact "0.7.0"
# or a caret range "^0.7.0"); empty when absent or unreadable.
read_pkg_spec() {
    node -e 'const j=require(process.argv[1]);const s=(j.dependencies||{})["dsh-code"];process.stdout.write(typeof s==="string"?s:"")' "$1" 2>/dev/null
}

# Rewrite the profile's `dsh-code` dependency spec to an exact version,
# tolerating a manifest with no `dependencies` block at all (which would
# otherwise make `j.dependencies["dsh-code"]=` throw a TypeError).
pin_dsh_code_spec() {  # $1 = profile_dir, $2 = version
    node -e 'const p=process.argv[1],v=process.argv[2];const j=require(p);(j.dependencies=j.dependencies||{})["dsh-code"]=v;require("fs").writeFileSync(p,JSON.stringify(j,null,2)+"\n")' "$1/package.json" "$2"
}

sync_dsh_code_profile() {
    local global_ver profile_ver after_ver spec
    local profile_dir="$HOME/.dsh/profiles/cli"
    local global_pkg_json

    # 0 = confirmed parity, 1 = skew detected, 2 = unverified (default).
    DSH_CODE_PARITY_STATE=2

    global_pkg_json="$(npm root -g 2>/dev/null)/dsh-code/package.json"
    global_ver="$(read_pkg_version "$global_pkg_json")"
    if [ -z "$global_ver" ]; then
        echo " [!] dsh-code: cannot determine global version — parity left unverified."
        return 1
    fi

    profile_ver="$(read_pkg_version "$profile_dir/node_modules/dsh-code/package.json")"

    if [ "$profile_ver" = "$global_ver" ]; then
        echo " [✓] dsh-code: profile runner $global_ver matches global bundle."
        # The resolved version matches, but the SPEC may still be a caret range
        # (e.g. ^0.7.0) that a later bare `pnpm install` in the profile could
        # drift within. Normalize it to the exact version when it isn't already.
        spec="$(read_pkg_spec "$profile_dir/package.json")"
        if [ "$spec" != "$global_ver" ]; then
            pin_dsh_code_spec "$profile_dir" "$global_ver"
            echo " [✓] dsh-code: profile spec pinned to exact $global_ver (was ${spec:-<none>})."
        fi
        DSH_CODE_PARITY_STATE=0
        return 0
    fi

    echo " [!] dsh-code: version skew (global $global_ver vs profile ${profile_ver:-<not mounted>}) — pinning profile to $global_ver."
    # pnpm only honors --save-exact on a FRESH add; upgrading an existing
    # "^x.y.z" spec preserves the caret, and `dsh plugin add` can exit 0 without
    # converging the tree (e.g. an existing ^0.x range is considered satisfied).
    # So normalize the spec AND re-read the RESOLVED version afterwards — trust
    # nothing from exit codes alone.
    if dsh plugin --profile cli add "dsh-code@${global_ver}" --save-exact 2>&1 \
        && pin_dsh_code_spec "$profile_dir" "$global_ver"
    then
        after_ver="$(read_pkg_version "$profile_dir/node_modules/dsh-code/package.json")"
        if [ "$after_ver" = "$global_ver" ]; then
            echo " [✓] dsh-code: profile pinned and verified at $global_ver."
            DSH_CODE_PARITY_STATE=0
            return 0
        fi
        echo " [✗] dsh-code: pin did not converge (resolved ${after_ver:-<none>} != $global_ver)."
        DSH_CODE_PARITY_STATE=1
        return 1
    fi

    echo " [✗] dsh-code: failed to pin profile to $global_ver."
    DSH_CODE_PARITY_STATE=1
    return 1
}

# ---------------------------------------------------------------------------
# dsh profile plugins & presets.
#
# These are DeepSeek Harness agent presets/plugins, NOT global CLI binaries, so
# they are version-managed separately from the `PACKAGES` loop above. Two kinds:
#
#   * npm bundle plugin — published to npm with a `dsh.bundle.patch`; installed
#     into the cli profile with `dsh plugin --profile cli add`, and (because
#     `dsh plugin` does not materialize package-declared presets) its bundled
#     preset directory is copied into the user preset root by hand.
#   * git-only preset — a GitHub repo whose `preset/` directory is copied into
#     the user preset root; no npm package exists for it.
# ---------------------------------------------------------------------------

# The user preset root dsh-agent-presets derives (<dshHome>/.agent-presets).
dsh_preset_root() {
    echo "${DSH_HOME:-$HOME/.dsh}/.agent-presets"
}

# Atomically replace a preset directory with a fresh copy from a source dir, so
# a mid-copy failure cannot leave a half-written preset (which discovery would
# then list as broken).
install_preset_dir() {  # $1 = src_dir, $2 = dst_dir
    local tmp="${2}.tmp.$$"
    rm -rf "$tmp"
    if cp -R "$1" "$tmp" 2>&1; then
        rm -rf "$2"
        mv "$tmp" "$2"
        return 0
    fi
    rm -rf "$tmp"
    return 1
}

# git-only preset: dsh-anchored-standard (xiaobright/dsh-anchored-standard).
# Track the remote HEAD commit in a marker file under the preset dir; re-clone
# only when the remote moves.
DSH_ANCHORED_STATE=2
sync_dsh_anchored_standard() {
    local id="anchored-standard"
    local repo="https://github.com/xiaobright/dsh-anchored-standard.git"
    local preset_dst="$(dsh_preset_root)/$id"
    local marker="$preset_dst/.sync-commit"
    local cache="$HOME/.dsh/cache/$id"
    local remote_commit local_commit

    DSH_ANCHORED_STATE=2
    remote_commit="$(git ls-remote "$repo" HEAD 2>/dev/null | awk '{print $1}')"
    if [ -z "$remote_commit" ]; then
        echo " [!] $id: cannot resolve remote HEAD — left unverified."
        return 1
    fi

    local_commit="$( [ -f "$marker" ] && cat "$marker" 2>/dev/null || echo "")"
    if [ "$remote_commit" = "$local_commit" ] && [ -d "$preset_dst" ]; then
        echo " [✓] $id: preset up to date at $remote_commit."
        DSH_ANCHORED_STATE=0
        return 0
    fi

    echo " -> $id: updating to $remote_commit..."
    if [ -d "$cache/.git" ]; then
        (cd "$cache" && git fetch --depth 1 origin main >/dev/null 2>&1 && git reset --hard origin/main >/dev/null 2>&1)
    else
        rm -rf "$cache"
        git clone --depth 1 "$repo" "$cache" >/dev/null 2>&1
    fi
    if [ ! -d "$cache/preset" ]; then
        echo " [✗] $id: clone/fetch failed; preset source missing."
        DSH_ANCHORED_STATE=1
        return 1
    fi
    mkdir -p "$(dsh_preset_root)"
    if install_preset_dir "$cache/preset" "$preset_dst"; then
        printf '%s\n' "$remote_commit" > "$marker"
        echo " [✓] $id: preset installed at $remote_commit."
        DSH_ANCHORED_STATE=0
        return 0
    fi
    echo " [✗] $id: preset copy failed."
    DSH_ANCHORED_STATE=1
    return 1
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

    # dsh-code is a global alias for `dsh --profile cli`; a plain npm install
    # cannot complete the setup — the plugin must also be registered with the
    # profile, pinned to the global version. Do that first, since no amount of
    # re-installing will help.
    if [ "$pkg" = "dsh-code" ]; then
        sync_dsh_code_profile
        if [ "$DSH_CODE_PARITY_STATE" -eq 0 ] && "$bin_name" --version >/dev/null 2>&1; then
            echo " [✓] Plugin registration succeeded: $bin_name --version OK"
            VERIFY_OK=0
            return 0
        fi
        echo " [!] Plugin registration did not fix $bin_name."
    fi

    # Retry install (the CLI process may have exited by now)
    npm_install_with_retry "$pkg"
    if [ "$NPM_INSTALL_OK" -eq 0 ] && "$bin_name" --version >/dev/null 2>&1; then
        # A global reinstall can resolve a DIFFERENT version than the profile
        # was just pinned to, silently re-opening the skew. Re-sync for dsh-code
        # before declaring success; never trust the parity flag across a reinstall.
        if [ "$pkg" = "dsh-code" ]; then
            sync_dsh_code_profile
            if [ "$DSH_CODE_PARITY_STATE" -ne 0 ]; then
                echo " [✗] dsh-code: post-reinstall parity still not confirmed."
                VERIFY_OK=1
                return 1
            fi
        fi
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
            # dsh-code's profile runner must be pinned to this fresh global
            # version BEFORE the binary is trusted as healthy.
            [ "$PACKAGE" = "dsh-code" ] && sync_dsh_code_profile
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
            # Re-pin the profile runner to the freshly upgraded global version.
            [ "$PACKAGE" = "dsh-code" ] && sync_dsh_code_profile
            verify_cli_binary "$PACKAGE"
        fi
    else
        # Even if up to date, verify the binary works — a previous
        # install may have silently skipped the native binary. For dsh-code,
        # also re-check version parity: a skew leaves --version green but the
        # session with zero tools/skills, so it must be caught here, not in
        # verify_cli_binary's failure path.
        if [ "$PACKAGE" = "dsh-code" ]; then
            sync_dsh_code_profile
        fi
        verify_cli_binary "$PACKAGE"
    fi
done

# dsh profile plugins & presets (not global CLIs).
echo "----------------------------------------------------"
echo "=== dsh profile plugins / presets ==="
sync_dsh_anchored_standard

echo ""
echo "=== Final health check summary ==="
FAILED_CLIS=()
for PACKAGE in "${PACKAGES[@]}"; do
    BIN_NAME=$(get_bin_name "$PACKAGE")
    # dsh-code additionally requires global/profile version parity; a skew
    # leaves --version green but the session unusable, so treat it as broken.
    if [ "$PACKAGE" = "dsh-code" ] && [ "$DSH_CODE_PARITY_STATE" -eq 1 ]; then
        echo " [✗] $BIN_NAME: BROKEN (global/profile version skew)"
        FAILED_CLIS+=("$BIN_NAME")
    elif [ "$PACKAGE" = "dsh-code" ] && [ "$DSH_CODE_PARITY_STATE" -eq 2 ]; then
        echo " [•] $BIN_NAME: UNVERIFIED (parity check skipped — registry/resolution unavailable)"
    elif command -v "$BIN_NAME" >/dev/null 2>&1 && "$BIN_NAME" --version >/dev/null 2>&1; then
        VERSION=$("$BIN_NAME" --version 2>/dev/null | head -1)
        echo " [✓] $BIN_NAME: $VERSION"
    else
        echo " [✗] $BIN_NAME: BROKEN"
        FAILED_CLIS+=("$BIN_NAME")
    fi
done

# Report the dsh preset state; only a hard failure (state 1) contributes to
# FAILED_CLIS. Unverified (state 2) is a warning, not fatal.
if [ "$DSH_ANCHORED_STATE" -eq 1 ]; then
    echo " [✗] dsh-anchored-standard: BROKEN (update failed)"
    FAILED_CLIS+=("dsh-anchored-standard")
elif [ "$DSH_ANCHORED_STATE" -eq 2 ]; then
    echo " [•] dsh-anchored-standard: UNVERIFIED"
else
    echo " [✓] dsh-anchored-standard: OK"
fi

if [ "${#FAILED_CLIS[@]}" -gt 0 ]; then
    echo ""
    echo " [!] The following CLIs failed verification: ${FAILED_CLIS[*]}"
    echo " [!] If a CLI process was running during upgrade, tomorrow's cron will retry."
    # Non-zero exit so cron/CI can detect a failed nightly update.
    exit 1
fi

echo ""
# (END)
