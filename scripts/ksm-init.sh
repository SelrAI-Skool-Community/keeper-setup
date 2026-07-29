#!/usr/bin/env bash
# ksm-init.sh — initialise the KSM profile from a one-time access token.
# Called by the keeper-setup skill (Phase 4 step 5) after the user has the
# one-time access token from the Vault UI.
#
# The token is NEVER accepted as a command-line argument: argv leaks into
# shell history and the process table. Two safe input paths:
#
#   ksm-init.sh              # opens a Terminal that prompts for the token,
#                            # auto-closes on success
#   ksm-init.sh --stdin      # reads the token from stdin (pipe it in)
#
# The auto-close pattern prevents the user from accidentally dictating into
# the live shell prompt after the token is consumed (voice dictation can leak
# a credential into a live prompt).
#
# After successful init, the script also discovers the KSM_SF_UID from the
# active app's shared folder and writes it to ~/.keeper/ksm-config.

set -u

discover_sf_uid() {
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
}

case "${1:-}" in
    --discover)
        # Internal: UID discovery only (called back from the Terminal window).
        discover_sf_uid
        exit 0
        ;;

    --stdin)
        IFS= read -r TOKEN
        if [ -z "$TOKEN" ]; then
            echo "==> No token received on stdin." >&2
            exit 1
        fi
        if ksm profile init "$TOKEN" 2>&1 | tee /tmp/ksm-init.out; then
            echo ""
            echo "==> KSM profile initialized."
        else
            echo "==> ksm profile init failed. See output above."
            exit 1
        fi
        discover_sf_uid
        ;;

    "")
        # Open a Terminal that prompts for the token and auto-closes on success.
        SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
        osascript <<OSA
tell application "Terminal"
    activate
    do script "echo '=== KEEPER SECRETS MANAGER INIT ==='; echo 'Paste the one-time token from the Vault UI here. The window auto-closes on success.'; echo ''; printf 'Token: '; IFS= read -r KSM_TOKEN; ksm profile init \\"\$KSM_TOKEN\\" && bash '$SELF' --discover && echo '' && echo 'OK — closing in 3s' && sleep 3 && exit"
end tell
OSA
        echo "==> Terminal opened. Paste your one-time token there."
        echo "==> Come back when the window has closed automatically."
        exit 0
        ;;

    *)
        echo "==> Refusing a token on the command line (argv lands in shell history" >&2
        echo "==> and the process table). Run with no arguments to get a Terminal" >&2
        echo "==> prompt, or pipe the token in: printf '%s' \"\$TOKEN\" | ksm-init.sh --stdin" >&2
        exit 2
        ;;
esac
