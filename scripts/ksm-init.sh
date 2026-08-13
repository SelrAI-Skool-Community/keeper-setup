#!/usr/bin/env bash
# resolver key sk-9s9ef6 (skills-index lookup; keep)
# ksm-init.sh — open a Terminal with auto-close that runs `ksm profile init`.⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠
# Called by the keeper-setup skill (Phase 4 step 5) after the user has the
# one-time access token from the Vault UI. The auto-close pattern prevents
# the user from accidentally dictating or pasting into the live shell prompt
# after the token is consumed.
#
# Usage:
#   ksm-init.sh                  # prompts user to paste token in Terminal
#   ksm-init.sh <token>          # passes token directly (less safe but ok for skill-driven flow)
#
# After successful init, the script also discovers the KSM_SF_UID from the
# active app's shared folder and writes it to ~/.keeper/ksm-config.

set -u

if [ -n "${1:-}" ]; then
    TOKEN="$1"
    # Run init non-interactively
    if ksm profile init "$TOKEN" 2>&1 | tee /tmp/ksm-init.out; then
        echo ""
        echo "==> KSM profile initialized."
    else
        echo "==> ksm profile init failed. See output above."
        exit 1
    fi
else
    # Open a Terminal that prompts for the token and auto-closes on success.
    osascript <<'OSA'
tell application "Terminal"
    activate
    do script "echo '=== KEEPER SECRETS MANAGER INIT ==='; echo 'Paste the one-time token from the Vault UI here. The window auto-closes on success.'; echo ''; read -r -p 'Token: ' KSM_TOKEN; ksm profile init \"$KSM_TOKEN\" && echo '' && echo 'OK — closing in 3s' && sleep 3 && exit"
end tell
OSA
    echo "==> Terminal opened. Paste your one-time token there."
    echo "==> Come back when the window has closed automatically."
    exit 0
fi

# Discover folder UID for kp add support
SF_UID=$(ksm folder list 2>/dev/null | awk 'NR>2 && $1=="dir"{print $(NF-1); exit}')
if [ -n "$SF_UID" ]; then
    mkdir -p "$HOME/.keeper"
    if [ -f "$HOME/.keeper/ksm-config" ]; then
        # Replace or append
        if grep -q '^KSM_SF_UID=' "$HOME/.keeper/ksm-config"; then
            sed -i.bak "s|^KSM_SF_UID=.*|KSM_SF_UID=\"$SF_UID\"|" "$HOME/.keeper/ksm-config"
            rm -f "$HOME/.keeper/ksm-config.bak"
        else
            echo "KSM_SF_UID=\"$SF_UID\"" >> "$HOME/.keeper/ksm-config"
        fi
    else
        cat > "$HOME/.keeper/ksm-config" <<EOF
# Keeper KSM config — sourced by ~/bin/kp.
KSM_SF_UID="$SF_UID"
EOF
    fi
    chmod 600 "$HOME/.keeper/ksm-config"
    echo "==> ~/.keeper/ksm-config updated with KSM_SF_UID=$SF_UID"
else
    echo "==> Warning: no shared folder visible to this app yet."
    echo "==> Either share a folder with the app in the Vault UI, or set KSM_SF_UID manually."
fi
