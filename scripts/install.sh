#!/usr/bin/env bash
# install.sh — one-shot Keeper Commander + KSM + kp wrapper installer.
# Idempotent. Safe to re-run.
# Does NOT log the user in (interactive, requires master password + 2FA).
# After this runs the user does:
#   1. keeper login <their-email>        (Commander auth, for the fallback path)
#   2. /keeper-setup Phase 3 + 4         (Admin Console + Vault UI clicks)
#   3. ksm-init.sh                       (consumes the one-time access token)

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> 1. Keeper Commander"
if command -v keeper >/dev/null 2>&1; then
    echo "  already installed: $(keeper version 2>&1 | head -1)"
else
    if ! command -v brew >/dev/null 2>&1; then
        echo "  Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install keeper-commander
fi

echo "==> 2. Keeper Secrets Manager CLI (ksm) with keyring extra"
if ! command -v pipx >/dev/null 2>&1; then
    if command -v brew >/dev/null 2>&1; then
        brew install pipx && pipx ensurepath
    else
        python3 -m pip install --user pipx && python3 -m pipx ensurepath
    fi
fi
if pipx list 2>/dev/null | grep -q "keeper-secrets-manager-cli"; then
    echo "  already installed: $(ksm --version 2>&1 | head -1 || true)"
    # Ensure keyring extra is present (pipx inject is idempotent)
    if ! pipx list 2>/dev/null | grep -A 4 "keeper-secrets-manager-cli" | grep -q keyring; then
        echo "  injecting keyring extra..."
        pipx inject keeper-secrets-manager-cli keyring
    fi
else
    pipx install 'keeper-secrets-manager-cli[keyring]'
fi

echo "==> 3. kp wrapper (KSM-first with Commander fallback)"
mkdir -p "$HOME/bin"
cp "$SKILL_DIR/scripts/kp" "$HOME/bin/kp"
cp "$SKILL_DIR/scripts/kp-commander-only" "$HOME/bin/kp-commander-only"
chmod +x "$HOME/bin/kp" "$HOME/bin/kp-commander-only"
echo "  ~/bin/kp installed (magic sentinel: $(head -2 "$HOME/bin/kp" | tail -1))"

echo "==> 4. PATH"
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    rcfile="$HOME/.zshrc"
    [ -f "$HOME/.bashrc" ] && rcfile="$HOME/.bashrc"
    if ! grep -q 'export PATH="$HOME/bin' "$rcfile" 2>/dev/null; then
        echo 'export PATH="$HOME/bin:$PATH"' >> "$rcfile"
        echo "  added ~/bin to PATH in $rcfile (restart shell to apply)"
    fi
fi

echo "==> 5. ksm folder UID config (template)"
mkdir -p "$HOME/.keeper"
if [ ! -f "$HOME/.keeper/ksm-config" ]; then
    cat > "$HOME/.keeper/ksm-config" <<EOF
# Keeper KSM config — sourced by ~/bin/kp.
# After /keeper-setup Phase 4 + ksm-init.sh, this gets populated with the
# Shared Folder UID returned by 'ksm folder list'. Without it, kp pass works
# (reads any KSM-visible record by title), but 'kp add' is disabled.
KSM_SF_UID=""
EOF
    chmod 600 "$HOME/.keeper/ksm-config"
    echo "  template written; populated by ksm-init.sh after Phase 4"
else
    echo "  already exists at ~/.keeper/ksm-config (leaving as-is)"
fi

echo ""
echo "==> Done. Next steps for the user:"
echo "  • Commander fallback path:    keeper login <your-email>"
echo "  • KSM primary path:           see /keeper-setup Phases 3, 4 in SKILL.md"
echo "  • Smoke test after setup:     $SKILL_DIR/scripts/smoke.sh"
