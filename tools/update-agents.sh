#!/bin/bash

# npm-manageable packages
PACKAGES=("@anthropic-ai/claude-code" "@openai/codex" "@qodercn-ai/qoderclicn" "@deepseek-ai/dsh" "@deepseek-harness-tui/dsh-tui")
PACKAGES_EXT=("@anthropic-ai/claude-code" "@openai/codex" "@google/gemini-cli" "@qwen-code/qwen-code" "@qodercn-ai/qoderclicn" "@mimo-ai/cli" "@moonshot-ai/kimi-code" "@deepseek-ai/dsh" "@deepseek-harness-tui/dsh-tui")

# Map each package to the executable it should expose on PATH.
# Implemented as a function instead of an associative array: the macOS
# system Bash is 3.2, which does not support `declare -A`.
pkg_bin() {
    case "$1" in
        "@anthropic-ai/claude-code") printf '%s\n' "claude" ;;
        "@openai/codex")             printf '%s\n' "codex" ;;
        "@google/gemini-cli")        printf '%s\n' "gemini" ;;
        "@qwen-code/qwen-code")      printf '%s\n' "qwen" ;;
        "@qodercn-ai/qoderclicn")    printf '%s\n' "qoderclicn" ;;
        "@mimo-ai/cli")              printf '%s\n' "mimo" ;;
        "@moonshot-ai/kimi-code")    printf '%s\n' "kimi" ;;
        "@deepseek-ai/dsh")          printf '%s\n' "dsh" ;;
        "@deepseek-harness-tui/dsh-tui") printf '%s\n' "dsh-tui" ;;
        *) return 1 ;;
    esac
}

# Run a command with an optional timeout. Uses GNU `timeout` or macOS `gtimeout`;
# falls back to running bare if neither is present.
# NPM_GLOBAL_PREFIX / NPM_GLOBAL_ROOT / TIMEOUT_BIN are set in the main body before use.
run_with_timeout() {
    local secs="$1"; shift
    if [ -n "$TIMEOUT_BIN" ]; then
        "$TIMEOUT_BIN" "$secs" "$@"
    else
        "$@"
    fi
}

# npm network settings, applied ONLY to npm invocations -- never exported into
# the script's environment. Rationale, both verified by measurement on this box:
#
#  1. Prefer a domestic mirror. registry.npmmirror.com serves matching sha512
#     for every tracked package, so npm's integrity check still guards every
#     download. Override with NPM_UPDATE_REGISTRY, or set it empty to keep the
#     default. The mirror is NOT always complete, however: it can be missing a
#     specific platform build, which is what NPM_FALLBACK_REGISTRY below covers.
#  2. The local proxy ($http_proxy, typically a VPN client on :10808) truncates
#     large tarballs: 1/3 full downloads via proxy vs 4/4 direct. So npm runs
#     with the proxy unset. cron has no proxy vars at all, so this only affects
#     interactive runs. Scoped to npm because other endpoints (antigravity.google)
#     are only reachable *through* the proxy -- a global unset breaks `agy`.

# Run a command (normally npm) with proxy variables removed from its
# environment and the registry pinned. Uses `env -u` rather than `unset` so the
# caller's shell -- and the agy step above -- keeps its own proxy settings.
# The default is resolved here (not at definition time) so that unsetting
# NPM_UPDATE_REGISTRY still yields the mirror; set it empty to keep npm's own
# default registry.
#
# NPM_REGISTRY_OVERRIDE wins over everything when non-empty, so a caller can
# point one invocation at a different registry. Pass it as an env prefix
# (`NPM_REGISTRY_OVERRIDE=... npm_env ...`), which keeps it scoped to that
# call. This exists because npm resolves duplicate --registry flags last-wins,
# so appending --registry after the caller's own would silently undo it.
npm_env() {
    local registry="${NPM_REGISTRY_OVERRIDE:-${NPM_UPDATE_REGISTRY-https://registry.npmmirror.com/}}"
    local registry_args=()
    if [ -n "$registry" ]; then
        registry_args=("--registry=$registry")
    fi
    env -u http_proxy -u https_proxy -u all_proxy \
        -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
        "$@" "${registry_args[@]}"
}

# Upstream registry, used only when the mirror demonstrably produced a binary
# that does not run. Some packages carry their native executable as an optional
# dependency that is an npm ALIAS to a platform-specific package version (e.g.
# @openai/codex's `@openai/codex-darwin-arm64` -> `npm:@openai/codex@<ver>-darwin-arm64`).
# The mirror can be missing one of those platform versions while having the
# main package, and npm treats a failed OPTIONAL dependency as non-fatal: it
# exits 0 and leaves a stub whose --version fails with "Missing optional
# dependency". No amount of retrying or cache-clearing fixes that -- only
# fetching from upstream does. Override with NPM_FALLBACK_REGISTRY.
NPM_FALLBACK_REGISTRY="${NPM_FALLBACK_REGISTRY-https://registry.npmjs.org/}"

# Transient-failure policy for npm: despite the mirror + proxy fix above, a
# connection can still reset mid-download (ECONNRESET / partial transfer), and
# npm does not always retry these itself. A bounded retry normally succeeds.
RETRY_ATTEMPTS=4
RETRY_DELAY=5

# Run a command up to RETRY_ATTEMPTS times, sleeping RETRY_DELAY between tries.
# Returns the last attempt's exit status. Used for read-only npm queries (e.g.
# `npm view`); package installs use npm_install_retry instead, which keys on the
# binary working rather than the exit code. Stdin is /dev/null so a retried
# command can never block waiting for input.
retry() {
    local attempt=1 rc=0
    while [ "$attempt" -le "$RETRY_ATTEMPTS" ]; do
        "$@" </dev/null
        rc=$?
        if [ "$rc" -eq 0 ]; then
            return 0
        fi
        if [ "$attempt" -lt "$RETRY_ATTEMPTS" ]; then
            echo "     [!] attempt $attempt/$RETRY_ATTEMPTS failed (rc=$rc); retrying in ${RETRY_DELAY}s..." >&2
            sleep "$RETRY_DELAY"
        fi
        attempt=$((attempt + 1))
    done
    return "$rc"
}

# Quietly check that a package's binary actually runs -- the same predicate
# verify_bin uses, without its output. Mirrors verify_bin's path construction.
bin_works() {
    local pkg="$1" bin npm_bin_dir npm_link
    bin="$(pkg_bin "$pkg")" || return 1
    [ -n "$bin" ] || return 1
    npm_bin_dir="${NPM_GLOBAL_PREFIX:+$NPM_GLOBAL_PREFIX/bin}"
    [ -n "$npm_bin_dir" ] && [ -d "$npm_bin_dir" ] || return 1
    npm_link="$npm_bin_dir/$bin"
    [ -e "$npm_link" ] || [ -L "$npm_link" ] || return 1
    run_with_timeout 30 "$npm_link" --version >/dev/null 2>&1
}

# Install/upgrade a global npm package, retrying until the binary WORKS.
# Keyed on the binary, not npm's exit code: when a native binary is an
# OPTIONAL dependency, a truncated download makes npm skip it and still exit 0,
# leaving a broken stub. Only "the binary runs" proves the install succeeded.
# If every retry fails, clear the cache once and try a final time -- a partial
# tarball there makes npm fail without touching the network.
#
# If the binary still does not run, the cause may not be transient at all: the
# mirror can be missing the package's platform build (see
# NPM_FALLBACK_REGISTRY). Retrying a mirror that does not have the artifact
# cannot help, so the last resort is one install from upstream.
#
# Output goes to a temp file, then indented: piping npm into sed would hide its
# exit status, and the per-attempt log must survive across retries.
npm_install_retry() {
    local pkg="$1" log attempt=1 rc=0
    log=$(mktemp)
    while [ "$attempt" -le "$RETRY_ATTEMPTS" ]; do
        npm_env npm install -g "$pkg" --fetch-retries=5 --fetch-retry-maxtimeout=120000 >>"$log" 2>&1
        rc=$?
        if [ "$rc" -eq 0 ] && bin_works "$pkg"; then
            sed 's/^/     /' "$log"; rm -f "$log"; return 0
        fi
        if [ "$attempt" -lt "$RETRY_ATTEMPTS" ]; then
            echo "  [!] Attempt $attempt/$RETRY_ATTEMPTS left '$pkg' not working (npm rc=$rc); retrying in ${RETRY_DELAY}s..." >>"$log"
            sleep "$RETRY_DELAY"
        fi
        attempt=$((attempt + 1))
    done
    echo "  [!] Still not working after $RETRY_ATTEMPTS attempts; clearing npm cache and retrying..." >>"$log"
    npm_env npm cache clean --force >>"$log" 2>&1
    npm_env npm install -g "$pkg" --fetch-retries=5 --fetch-retry-maxtimeout=120000 >>"$log" 2>&1
    if [ -n "$NPM_FALLBACK_REGISTRY" ] && ! bin_works "$pkg"; then
        echo "  [!] $pkg still not working; retrying once from $NPM_FALLBACK_REGISTRY (mirror may lack this platform build)..." >>"$log"
        # Only the registry changes; the alias targets are fetched with it.
        NPM_REGISTRY_OVERRIDE="$NPM_FALLBACK_REGISTRY" \
            npm_env npm install -g "$pkg" --fetch-retries=5 --fetch-retry-maxtimeout=120000 >>"$log" 2>&1
    fi
    sed 's/^/     /' "$log"; rm -f "$log"
    bin_works "$pkg"
}

# Verify the npm-managed binary symlink exists, runs, and is the one on PATH.
# Returns 0 on success, 1 on failure. Prints the failure reason.
verify_bin() {
    local pkg="$1"
    local bin
    bin="$(pkg_bin "$pkg")"
    local npm_bin_dir npm_link
    npm_bin_dir="${NPM_GLOBAL_PREFIX:+$NPM_GLOBAL_PREFIX/bin}"
    npm_link="$npm_bin_dir/$bin"

    # Missing mapping is a hard failure, not a silent skip.
    if [ -z "$bin" ]; then
        echo "  [!] No binary mapping for $pkg; cannot verify."
        return 1
    fi

    # Guard: never operate on a degenerate path (e.g. "/bin" if npm prefix failed).
    if [ -z "$NPM_GLOBAL_PREFIX" ] || [ -z "$npm_bin_dir" ] \
       || [ "$(dirname "$npm_bin_dir")" = "/" ] || [ ! -d "$npm_bin_dir" ]; then
        echo "  [!] Unresolved npm bin dir ('$npm_bin_dir'); refusing to verify $bin."
        return 1
    fi

    # The npm-managed symlink must exist.
    if [ ! -e "$npm_link" ] && [ ! -L "$npm_link" ]; then
        echo "  [!] Binary '$bin' not linked in $npm_bin_dir."
        return 1
    fi

    # Run --version against the npm symlink directly (capped so a first-run prompt can't hang).
    if ! run_with_timeout 30 "$npm_link" --version >/dev/null 2>&1; then
        echo "  [!] '$npm_link --version' failed or timed out; npm binary is broken."
        return 1
    fi

    # Warn (not fail) if PATH resolves $bin to a different file than the npm-managed link.
    local on_path
    on_path=$(command -v "$bin" 2>/dev/null || true)
    if [ -n "$on_path" ] \
       && [ "$(readlink -f "$on_path" 2>/dev/null)" != "$(readlink -f "$npm_link" 2>/dev/null)" ]; then
        echo "  [!] Note: '$bin' on PATH ($on_path) shadows the npm-managed binary ($npm_link)."
    fi

    echo "  -> Verified: $bin is available ($npm_link)."
    return 0
}

# Attempt to repair a broken/missing npm global bin symlink for a package.
# Reads the package.json "bin" field, removes leftover .<bin>-XXXX temp links,
# recreates the proper symlink, then re-verifies. Returns 0 on success.
repair_bin() {
    local pkg="$1"
    local bin
    bin="$(pkg_bin "$pkg")"
    local npm_bin_dir pkg_dir target

    npm_bin_dir="${NPM_GLOBAL_PREFIX:+$NPM_GLOBAL_PREFIX/bin}"
    pkg_dir="$NPM_GLOBAL_ROOT/$pkg"

    if [ -z "$bin" ] || [ -z "$NPM_GLOBAL_ROOT" ] || [ ! -d "$pkg_dir" ]; then
        return 1
    fi

    # Guard: never rm/ln in a degenerate dir (e.g. "/bin" if npm prefix failed).
    if [ -z "$npm_bin_dir" ] || [ "$(dirname "$npm_bin_dir")" = "/" ] || [ ! -d "$npm_bin_dir" ]; then
        echo "  [!] Unresolved npm bin dir ('$npm_bin_dir'); refusing to repair $bin."
        return 1
    fi

    # Resolve the script path from package.json "bin" via node (always available with npm).
    # Only the exact bin name is accepted; no guessing for multi-bin packages.
    target=$(node -e '
        const fs = require("fs");
        const p = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
        const b = p.bin || {};
        const out = typeof b === "string" ? b : (b[process.argv[2]] || "");
        process.stdout.write(out || "");
    ' "$pkg_dir/package.json" "$bin" 2>/dev/null)

    if [ -z "$target" ]; then
        echo "  [!] Could not resolve bin target for $pkg."
        return 1
    fi

    echo "  -> Repairing: relinking $bin -> $pkg_dir/$target"

    # Remove leftover npm temp symlinks (.<bin>-XXXX); ln -sfn replaces the final
    # name even if it is an existing symlink to a directory.
    rm -f "$npm_bin_dir"/."$bin"-* 2>/dev/null

    # Recreate the symlink using an absolute target derived from npm root -g.
    if ! ln -sfn "$pkg_dir/$target" "$npm_bin_dir/$bin" 2>/dev/null; then
        echo "  [!] Failed to create symlink $npm_bin_dir/$bin."
        return 1
    fi

    verify_bin "$pkg"
}

# Ensure the binary is available. Tries: verify -> relink repair -> reinstall -> verify.
ensure_bin() {
    local pkg="$1"
    if verify_bin "$pkg"; then
        return 0
    fi
    echo "  -> Attempting repair (relink)..."
    if repair_bin "$pkg"; then
        return 0
    fi
    echo "  -> Relink did not help; reinstalling $pkg..."
    npm_install_retry "$pkg"
    verify_bin "$pkg"
}

# Select package set based on --ext flag
if [ "$1" = "--ext" ]; then
    SELECTED_PACKAGES=("${PACKAGES_EXT[@]}")
else
    SELECTED_PACKAGES=("${PACKAGES[@]}")
fi

# Pretty banner (Unicode box) on a terminal; plain ASCII banner when piped
# to a log file.
banner() {
    local title="$1"
    if [ -t 1 ]; then
        local width=52 pad_l pad_r line
        pad_l=$(( (width - ${#title}) / 2 ))
        pad_r=$(( width - ${#title} - pad_l ))
        printf -v line '%*s' "$width" ' '
        line="${line// /═}"
        printf '╔%s╗\n' "$line"
        printf '║%*s%s%*s║\n' "$pad_l" '' "$title" "$pad_r" ''
        printf '╚%s╝\n' "$line"
    else
        echo "== $title =="
    fi
}

# Render a duration in whole seconds as "1h 2m 3s", "2m 3s" or "3s".
fmt_duration() {
    local s="$1"
    if [ "$s" -ge 3600 ]; then
        printf '%dh %dm %ds' $((s/3600)) $((s%3600/60)) $((s%60))
    elif [ "$s" -ge 60 ]; then
        printf '%dm %ds' $((s/60)) $((s%60))
    else
        printf '%ds' "$s"
    fi
}

# Print the closing banner + elapsed time, and keep the caller's exit code.
finish() {
    local rc=$?
    local end_time elapsed
    end_time=$(date +%s)
    elapsed=$((end_time - START_TIME))
    echo ""
    echo "End time: $(date '+%Y-%m-%d %H:%M:%S')"
    banner "Done in $(fmt_duration "$elapsed")"
    exit "$rc"
}

START_TIME=$(date +%s)
trap finish EXIT

banner "AI Agents Update"
echo "Start time: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

echo "=== Antigravity CLI (agy) ==="
echo "--------------------------------------------------"

AGY_BIN="$HOME/.local/bin/agy"

if [ ! -f "$AGY_BIN" ]; then
    echo "  [!] Antigravity CLI is not installed."
    echo "  -> Installing via curl..."
    curl -fsSL https://antigravity.google/cli/install.sh | bash
else
    INSTALLED_VERSION=$("$AGY_BIN" --version 2>/dev/null | head -1)
    echo "  Current version: $INSTALLED_VERSION"
    echo "  Note: Antigravity CLI auto-updates in the background."
    echo "  Running $AGY_BIN update"
    $AGY_BIN update
fi

echo ""
echo "=== npm packages: ${SELECTED_PACKAGES[*]} ==="

INSTALLED_LIST=$(npm_env npm list -g --depth=0 2>/dev/null)

# Resolve npm globals once (used by verify_bin/repair_bin) instead of per package.
NPM_GLOBAL_PREFIX="$(npm_env npm prefix -g 2>/dev/null)"
NPM_GLOBAL_ROOT="$(npm_env npm root -g 2>/dev/null)"
TIMEOUT_BIN="$(command -v timeout 2>/dev/null || command -v gtimeout 2>/dev/null || true)"
if [ -z "$TIMEOUT_BIN" ]; then
    echo "  [!] Neither 'timeout' nor 'gtimeout' found; --version probes will run uncapped."
fi

VERIFY_FAILURES=0

for PACKAGE in "${SELECTED_PACKAGES[@]}"; do
    echo "--------------------------------------------------"
    echo "Checking $PACKAGE..."

    INSTALLED_VERSION=$(echo "$INSTALLED_LIST" | grep " $PACKAGE@" | awk -F@ '{print $NF}')

    if [ -z "$INSTALLED_VERSION" ]; then
        # npm list -g misses binaries not installed via npm (e.g. corepack-
        # managed pnpm). Before assuming "not installed" and reinstalling
        # (which collides with the existing shim: EEXIST), probe the binary
        # directly. If it runs, fall through to the version-compare path
        # rather than a destructive reinstall.
        bin="$(pkg_bin "$PACKAGE")"
        if [ -n "$bin" ] && command -v "$bin" >/dev/null 2>&1 \
           && run_with_timeout 30 "$bin" --version >/dev/null 2>&1; then
            INSTALLED_VERSION=$("$bin" --version 2>/dev/null | tail -1)
            echo "  Current version: $INSTALLED_VERSION (not npm-managed; binary probes OK)"
        else
            echo "  [!] $PACKAGE is not installed."
            echo "  -> Installing..."
            npm_install_retry "$PACKAGE"
            ensure_bin "$PACKAGE" || VERIFY_FAILURES=$((VERIFY_FAILURES+1))
            continue
        fi
    fi

    echo "  Current version: $INSTALLED_VERSION"

    LATEST_VERSION=$(retry npm_env npm view "$PACKAGE" version 2>/dev/null)

    if [ -z "$LATEST_VERSION" ]; then
        echo "  [!] Could not fetch latest version for $PACKAGE."
        ensure_bin "$PACKAGE" || VERIFY_FAILURES=$((VERIFY_FAILURES+1))
        continue
    fi

    echo "  Latest version:  $LATEST_VERSION"

    if [ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]; then
        if [ "$(printf '%s\n' "$INSTALLED_VERSION" "$LATEST_VERSION" | sort -V | head -n1)" = "$INSTALLED_VERSION" ]; then
             echo "  -> Update available. Upgrading $PACKAGE..."
             npm_install_retry "$PACKAGE"
             ensure_bin "$PACKAGE" || VERIFY_FAILURES=$((VERIFY_FAILURES+1))
        else
             echo "  -> Installed version seems newer or same (sanity check)."
             ensure_bin "$PACKAGE" || VERIFY_FAILURES=$((VERIFY_FAILURES+1))
        fi
    else
        echo "  -> Up to date."
        ensure_bin "$PACKAGE" || VERIFY_FAILURES=$((VERIFY_FAILURES+1))
    fi
done

if [ "$VERIFY_FAILURES" -gt 0 ]; then
    echo "--------------------------------------------------"
    echo "[!] $VERIFY_FAILURES package(s) failed final verification."
    exit 1
fi

echo "--------------------------------------------------"
echo "All packages verified."

