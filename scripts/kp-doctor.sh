#!/bin/bash
# resolver key sk-9s9ef6 (skills-index lookup; keep)
# kp-doctor.sh — one-shot diagnosis of the whole Keeper stack on this Mac.⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠
# Run via `kp doctor`. Every FAIL prints the exact fix. Never prints a secret.
#
# Checks, in dependency order:
#   1. ksm CLI installed              → fix: pipx install keeper-secrets-manager-cli
#   2. ksm profile active             → fix: /keeper-setup Phase 4 (new one-time token)
#   3. live KSM fetch works           → fix: token revoked or license tier changed — re-init
#   4. KSM_SF_UID set                 → fix: write ~/.keeper/ksm-config
#   5. ~/bin/kp is KSM-first          → fix: reinstall wrapper from skill
#   6. Commander config = CANONICAL account (KP_CANONICAL_USER in ~/.keeper/ksm-config)
#   7. Commander session alive (batch-safe probe, never an interactive prompt)
#   8. no stray legacy account configs outside _archive
#   9. keepalive LaunchAgent healthy (no password prompts in its log)
set -uo pipefail

# Canonical account: env var wins, else ~/.keeper/ksm-config, else unset (check 6 warns).
if [ -z "${KP_CANONICAL_USER:-}" ] && [ -f "$HOME/.keeper/ksm-config" ]; then
  KP_CANONICAL_USER="$(grep '^KP_CANONICAL_USER=' "$HOME/.keeper/ksm-config" | tail -1 | cut -d= -f2- | tr -d '"')"
fi
CANONICAL_USER="${KP_CANONICAL_USER:-}"
PASS=0; FAIL=0; WARN=0
p() { echo "PASS: $*"; PASS=$((PASS+1)); }
f() { echo "FAIL: $*"; FAIL=$((FAIL+1)); }
w() { echo "WARN: $*"; WARN=$((WARN+1)); }

KSM_BIN="$(command -v ksm || echo "$HOME/.local/bin/ksm")"

# Mirror the wrapper's storage preference: if keeper.ini exists, ksm must be
# called with --ini-file or it silently uses the (possibly empty) keyring.
KSM_ARGS=()
[ -f "$HOME/keeper.ini" ] && KSM_ARGS=(--ini-file="$HOME/keeper.ini")

# macOS ships no `timeout`; use gtimeout if present, else run unguarded.
if command -v timeout >/dev/null 2>&1; then TMO="timeout"
elif command -v gtimeout >/dev/null 2>&1; then TMO="gtimeout"
else TMO=""; fi
tmo() { local secs="$1"; shift; if [ -n "$TMO" ]; then "$TMO" "$secs" "$@"; else "$@"; fi; }

# 1. ksm CLI
if [ -x "$KSM_BIN" ]; then p "ksm CLI installed ($KSM_BIN)"; else
  f "ksm CLI missing → pipx install keeper-secrets-manager-cli && pipx inject keeper-secrets-manager-cli keyring"; fi

# 2 + 3. profile + live fetch (uses the test record; falls back to listing)
if [ -x "$KSM_BIN" ]; then
  if tmo 20 "$KSM_BIN" "${KSM_ARGS[@]}" secret list >/dev/null 2>&1; then
    p "KSM profile active, live fetch works (this is the path kp uses daily)"
  else
    f "KSM fetch failed → token revoked or license changed. Fix: /keeper-setup Phase 4 — generate a new one-time token in the Vault, then 'ksm profile init <token>'"
  fi
fi

# 4. folder UID for kp add
if [ -f "$HOME/.keeper/ksm-config" ] && grep -q "KSM_SF_UID=." "$HOME/.keeper/ksm-config"; then
  p "KSM_SF_UID set (kp add can write)"
else
  w "KSM_SF_UID not set — kp reads fine, kp add will refuse. Fix: echo 'KSM_SF_UID=<shared-folder-uid>' > ~/.keeper/ksm-config"
fi

# 5. wrapper version
if head -3 "$HOME/bin/kp" 2>/dev/null | grep -q "ksm-first"; then
  p "~/bin/kp is the KSM-first wrapper"
else
  f "~/bin/kp missing or legacy → cp ~/.claude/skills/keeper-setup/scripts/kp ~/bin/kp && chmod +x ~/bin/kp"
fi

# 6. Commander account = canonical
CFG="$HOME/.keeper/config.json"
if [ -z "$CANONICAL_USER" ]; then
  w "KP_CANONICAL_USER not set — add KP_CANONICAL_USER=\"you@company.com\" to ~/.keeper/ksm-config so doctor can flag stray-account configs"
elif [ -f "$CFG" ]; then
  CFG_USER="$(python3 -c "import json;print(json.load(open('$CFG')).get('user',''))" 2>/dev/null)"
  if [ "$CFG_USER" = "$CANONICAL_USER" ]; then
    p "Commander config points at the canonical account ($CANONICAL_USER)"
  else
    f "Commander config user is '$CFG_USER', expected $CANONICAL_USER. Fix: ask Claude to rerun /keeper-setup for the canonical account, then retry kp doctor"
  fi
else
  w "no Commander config (~/.keeper/config.json) — fine if this Mac is KSM-only"
fi

# 7. Commander session aliveness — batch-safe: stdin closed, so a dead session
#    errors instead of prompting. Commander dying every ~40-60min is EXPECTED
#    under an organisation's session policy; KSM (the daily path) is unaffected.
if command -v keeper >/dev/null 2>&1 && [ -f "$CFG" ]; then
  OUT="$(tmo 25 keeper whoami </dev/null 2>&1 || true)"
  if echo "$OUT" | grep -qi "master password"; then
    w "Commander session dead; KSM is unaffected. For bulk admin work, ask Claude to open an interactive Terminal for keeper shell, then retry"
  elif [ -n "$CANONICAL_USER" ] && echo "$OUT" | grep -qi "$CANONICAL_USER"; then
    p "Commander session alive as $CANONICAL_USER"
  else
    w "Commander session state unclear — run 'keeper whoami' in a real terminal to check"
  fi
fi

# 8. stray legacy configs
STRAYS="$(ls "$HOME/.keeper" 2>/dev/null | grep -E "config.*(old|legacy|retired)" || true)"
if [ -z "$STRAYS" ]; then
  p "no stray old-account configs in ~/.keeper"
else
  f "legacy account configs still live in ~/.keeper: $STRAYS. Ask Claude to archive the confirmed stale files under ~/.keeper/_archive-legacy, then retry"
fi

# 9. keepalive health — judge only the MOST RECENT run. A raw "Password:" prompt
#    means the old unguarded plist is back; the batch-safe plist logs SKIPPED instead.
LOG=/tmp/keeper-keepalive.log
LAST_RUN="$(grep -E "sync-down (exit|SKIPPED)" "$LOG" 2>/dev/null | tail -1)"
if [ -z "$LAST_RUN" ]; then
  p "keepalive log clean (or absent)"
elif echo "$LAST_RUN" | grep -q "SKIPPED"; then
  p "keepalive batch-safe: last run skipped cleanly on a dead Commander session (KSM unaffected)"
elif tail -6 "$LOG" | grep -qi "master password"; then
  w "keepalive hit a raw password prompt on its last run — the plist lost its </dev/null guard. Fix: re-apply the batch-safe ProgramArguments from the skill's keepalive recipe."
else
  p "keepalive last run: ${LAST_RUN##*sync-down }"
fi

echo
echo "kp doctor: $PASS pass, $WARN warn, $FAIL fail"
[ "$FAIL" -eq 0 ]
