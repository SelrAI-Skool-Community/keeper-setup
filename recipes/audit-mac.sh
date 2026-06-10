#!/usr/bin/env bash
# audit-mac.sh — scan a Mac for credential files.
# READ-ONLY. Prints only LOCATIONS and counts, never values.
# Use to plan a credential migration into Keeper.

set -uo pipefail

echo "=== Mac credential audit ==="
echo "Run by: $USER on $(hostname)"
echo "Date: $(date)"
echo ""

echo "--- 1. ~/.claude/secrets/ (Claude Code secret files) ---"
[ -d "$HOME/.claude/secrets" ] && ls -la "$HOME/.claude/secrets/" | awk '{print "  " $9 "  (" $5 " bytes)"}' || echo "  (none)"
echo ""

echo "--- 2. .env files on $HOME (top 4 levels, excluding archives/node_modules) ---"
find "$HOME" -maxdepth 4 -name ".env*" \
    -not -path "*/node_modules/*" \
    -not -path "*/.Trash/*" \
    -not -path "*/Archive/*" \
    -not -path "*/.git/*" \
    2>/dev/null | sed 's/^/  /' | head -30
echo ""

echo "--- 3. PEM / key files ---"
find "$HOME" -maxdepth 4 \( -name "*.pem" -o -name "*.key" -o -name "id_rsa" -o -name "id_ed25519" \) \
    -not -path "*/node_modules/*" -not -path "*/.Trash/*" 2>/dev/null | sed 's/^/  /' | head -20
echo ""

echo "--- 4. Google Workspace creds ---"
[ -d "$HOME/.config/gws" ] && ls "$HOME/.config/gws/" 2>/dev/null | grep -E '\.json$' | sed 's/^/  ~\/.config\/gws\//' || echo "  (none — Google Workspace CLI not configured)"
echo ""

echo "--- 5. ~/.claude.json MCP env blocks ---"
if [ -f "$HOME/.claude.json" ]; then
    jq -r '.mcpServers | to_entries[] | select(.value.env != null and (.value.env | length) > 0) | "  \(.key): \(.value.env | keys | join(", "))"' "$HOME/.claude.json" 2>/dev/null | head -20
fi
echo ""

echo "--- 6. macOS Keychain (common API services only) ---"
security dump-keychain 2>/dev/null | grep -E '"svce"<blob>=' | sort -u | grep -iE "claude|anthropic|openai|stripe|aws|github|keeper" | sed 's/^/  /' | head -10
echo ""

echo "--- 7. Shell rc files referencing tokens ---"
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zprofile"; do
    if [ -f "$rc" ]; then
        n=$(grep -cE "^export (.*_(TOKEN|KEY|SECRET|PASSWORD)=)" "$rc" 2>/dev/null || echo 0)
        echo "  $rc: $n cred-looking exports"
    fi
done
echo ""

echo "=== End audit ==="
echo "Next: for each cred location found above, decide:"
echo "  A) Migrate to Keeper (run recipes/import-env-file.py for .env, or keeper record-add for one-offs)"
echo "  B) Leave in place (working copy for a script that reads it directly)"
echo "  C) Delete (duplicate, archive, or already-leaked)"
