#!/usr/bin/env bash
# resolver key sk-9s9ef6 (skills-index lookup; keep)
# keeper-setup smoke test.⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠
# Verifies the skill's evidence layer is in place + SKILL.md is valid +
# (when run on a machine that has the install done) the KSM/Commander
# stack is actually working.
set -u

FAILS=0
ok()   { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILS=$((FAILS+1)); }
warn() { echo "WARN: $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$SCRIPT_DIR/.."

echo "== keeper-setup smoke =="
echo ""

# --- Layer 1: skill structure -------------------------------------------------

if [[ -s "$SKILL_DIR/SKILL.md" ]]; then
  if head -5 "$SKILL_DIR/SKILL.md" | grep -q "^name: keeper-setup"; then
    ok "SKILL.md present with valid frontmatter"
  else
    fail "SKILL.md missing or malformed frontmatter"
  fi
else
  fail "SKILL.md missing"
fi

for f in README.md START-HERE.md CLOSEOUT.md SETUP-PROMPT.md CHANGELOG.md REFERENCE.md LEGACY-COMMANDER-PATH.md ORGANISE-PLAYBOOK.md RATE-LIMITS.md RECORD-TYPES.md COLOURS.md; do
  if [[ -s "$SKILL_DIR/$f" ]]; then
    ok "$f present"
  else
    fail "$f missing or empty"
  fi
done

if [[ -d "$SKILL_DIR/examples" ]] && ls "$SKILL_DIR/examples"/*.md >/dev/null 2>&1; then
  ok "examples/ present with .md files"
else
  warn "examples/ missing or empty"
fi

desc=$(awk '/^description:/{flag=1} /^---/{if(flag>1) exit; flag++} flag==1' "$SKILL_DIR/SKILL.md" | head -3)
if echo "$desc" | grep -qiE 'use when|trigger|says|paste'; then
  ok "description has use-when clause"
else
  warn "description lacks explicit use-when clause"
fi

for s in install.sh ksm-init.sh seed-folder.sh kp kp-commander-only kp-doctor.sh validate_skill_bundle.py; do
    if [[ -x "$SKILL_DIR/scripts/$s" ]]; then
        ok "scripts/$s present and executable"
    else
        fail "scripts/$s missing or not executable"
    fi
done

if command -v python3 >/dev/null 2>&1; then
    if python3 "$SKILL_DIR/scripts/validate_skill_bundle.py" >/tmp/keeper-setup-bundle-validate.out 2>&1; then
        ok "bundle validator passes"
    else
        fail "bundle validator failed: $(cat /tmp/keeper-setup-bundle-validate.out)"
    fi
else
    warn "python3 missing; skipped bundle validator"
fi

# Magic-string sentinel in the new KSM-first kp
if head -3 "$SKILL_DIR/scripts/kp" | grep -q "kp-version: ksm-first"; then
    ok "scripts/kp has ksm-first sentinel"
else
    fail "scripts/kp is missing the ksm-first sentinel — Phase 0 detection will fail"
fi

# --- Layer 2: live install state on this Mac (warnings only) -----------------

echo ""
echo "-- live install checks (informational) --"

command -v keeper >/dev/null 2>&1 \
    && ok "keeper Commander on PATH ($(keeper version 2>&1 | head -1))" \
    || warn "keeper Commander not installed yet"

command -v ksm >/dev/null 2>&1 \
    && ok "ksm CLI on PATH" \
    || warn "ksm CLI not installed yet"

if command -v kp >/dev/null 2>&1; then
    if head -3 "$(command -v kp)" 2>/dev/null | grep -q "kp-version: ksm-first"; then
        ok "~/bin/kp is KSM-first"
    else
        warn "~/bin/kp exists but is NOT the KSM-first version (silent-fail or commander-only)"
    fi
else
    warn "kp not on PATH yet"
fi

if [ -f "$HOME/.keeper/ksm-config" ] && grep -q '^KSM_SF_UID=".\+"' "$HOME/.keeper/ksm-config" 2>/dev/null; then
    ok "~/.keeper/ksm-config has a populated KSM_SF_UID"
else
    warn "~/.keeper/ksm-config not populated yet — kp add will be disabled"
fi

# Active ksm profile (handles both keyring and ini storage)
INI_FLAG=()
[ -f "$HOME/keeper.ini" ] && INI_FLAG=(--ini-file="$HOME/keeper.ini")
if command -v ksm >/dev/null 2>&1 && ksm "${INI_FLAG[@]}" profile list 2>/dev/null | grep -q '^\s*\*'; then
    ok "ksm has an active profile"
else
    warn "ksm has no active profile — run ksm-init.sh after Phase 4"
fi

echo ""
if [[ $FAILS -eq 0 ]]; then
  echo "SMOKE PASS"
  exit 0
fi
echo "SMOKE FAIL ($FAILS check(s) failed)"
exit 1
