---
name: keeper-setup
description: "FULLY AUTONOMOUS Keeper credential setup for Claude Code (and Codex, Cursor, any agentic CLI). Installs Keeper Commander + Keeper Secrets Manager CLI, walks the user through 5 Vault UI clicks to mint a long-lived KSM token, and installs the KSM-first `kp` wrapper at `~/bin/kp`. End state: `kp pass <record>` returns the value silently with zero master-password prompts, zero 2FA, forever. Use when the user says 'connect my Keeper', 'set up Keeper', 'install the password manager', 'set up credentials', 'fix the 2FA loop', 'my keeper keeps logging me out', or when `kp` is missing from the machine."
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
metadata:
  category: Productivity & Integrations
  tags: [keeper, password-manager, credentials, secrets, security, ksm, autonomous, team]
  audience: Any business owner or team with a Keeper Business account
  time-to-complete: 10-15 minutes (most of it is the user clicking through Admin Console + Vault UI once)
  cost-to-user: $0 (uses an existing Keeper seat; KSM is an enterprise add-on, included on some tiers)
  autonomy-bar: "User signs in to Keeper Admin Console once, clicks 5 things in the Vault UI, pastes one one-time token into a Terminal that auto-closes. Everything else — install, config, wrapper deploy, test — runs from Claude silently."
  shipping: "Lives at ~/.claude/skills/keeper-setup/. Distribute to a team via a shared skill repository synced to GitHub."
  owner: Selr AI
---

# Keeper Setup — KSM-first

> **The promise:** after this skill runs, the user runs `kp pass mapbox` from any shell or Claude session and the value comes back silently. Forever. No 2FA prompts. No "your session has expired." No master password re-entry.
>
> **The trick:** Keeper Secrets Manager (KSM) uses a long-lived application token that lives in macOS Keychain. It authenticates independently of the regular Keeper login session, so session-timeout enforcement policies (common on managed/MSP-administered accounts) never interrupt it — no more `persistent_login` dying and forcing re-auth.
>
> **Hard rule:** the user's **master password NEVER enters Claude chat**. Master-password prompts go into a real Terminal window that this skill opens via AppleScript. If you (the agent) are about to ask the user to type or paste their master password into chat — **STOP**. Use the Terminal pattern.

---

## Autonomy bar

| User DOES | User DOES NOT |
|---|---|
| Sign in to Keeper Admin Console once (browser) | Open Terminal manually |
| Click 5 things in the Vault UI (create Shared Folder, create KSM Application, share folder with app, generate token, transfer it into the agent-opened terminal) | Paste a master password or KSM token into Claude chat |
| Paste the one-time KSM token into a Terminal window the skill opens (auto-closes on success) | Type the same code in two places |
| Confirm a couple of yes/no questions in chat (e.g. account email) | Run brew, pipx, keeper, ksm commands manually |
| Restart Claude Code at the end so `~/bin/kp` is on PATH for new shells | Edit `.zshrc`, `.bashrc`, or any config |

If you're about to ask the user to do something not in the left column — pause and check the skill's patterns first. If a step fails, retry it, install whatever is missing, and continue. Never stop to wait for outside help.

---

## Trigger phrases (use when)

The skill auto-invokes on any of:
- "Connect my Keeper" / "set up Keeper" / "install the password manager"
- "Set up credentials"
- "Fix the 2FA loop" / "my Keeper keeps logging me out" / "Keeper sessions die"
- "Bring Keeper into Claude Code" / "set up KSM"
- A `kp search` is attempted and `kp` returns command-not-found.

---

## Phase 0 — Preflight (10 seconds)

Detect what's already installed so this skill skips work already done.

```bash
PHASE=1
command -v keeper >/dev/null 2>&1 || PHASE=1
command -v ksm >/dev/null 2>&1 || PHASE=1
if command -v kp >/dev/null 2>&1 && head -2 "$(command -v kp)" 2>/dev/null | grep -q "kp-version: ksm-first"; then : ; else PHASE=5; fi
INI_FLAG=()
[ -f "$HOME/keeper.ini" ] && INI_FLAG=(--ini-file="$HOME/keeper.ini")
ksm "${INI_FLAG[@]}" profile list 2>/dev/null | grep -q '^\s*\*' || PHASE=$((PHASE > 3 ? PHASE : 3))
[ -f "$HOME/.keeper/ksm-config" ] && grep -q '^KSM_SF_UID="..*"' "$HOME/.keeper/ksm-config" || PHASE=$((PHASE > 4 ? PHASE : 4))
echo "Start at Phase $PHASE"
```

If everything passes — run `scripts/smoke.sh` and exit clean.

---

## Phase 1 — Install both CLIs

```bash
~/.claude/skills/keeper-setup/scripts/install.sh
```

What this does:
1. `brew install keeper-commander` if missing (installs Homebrew first if needed)
2. `pipx install 'keeper-secrets-manager-cli[keyring]'` if missing — the `[keyring]` extra means the KSM profile lives in macOS Keychain (not a plaintext file)
3. Deploys `scripts/kp` to `~/bin/kp` AND `scripts/kp-commander-only` to `~/bin/kp-commander-only`
4. Ensures `~/bin` is on PATH in `.zshrc`
5. Writes a template `~/.keeper/ksm-config` (populated in Phase 4)

Verify: `keeper version` and `ksm --version` both return values; `head -2 ~/bin/kp` shows the magic sentinel `# kp-version: ksm-first-2026-05-30`.

If the install fails, retry it — the script is idempotent and installs missing dependencies on the way through.

---

## Phase 2 — Ask for Keeper email (the only thing typed in chat)

Use `AskUserQuestion`:
- Q: "What's the email on your Keeper account?"
- Options: a best-guess based on context, "Other (paste custom)"

**Do NOT ask for the master password here.** Hard rule.

---

## Phase 3 — Enable Secrets Manager on the user's role (Admin Console)

The user must navigate a browser. Narrate the exact path.

1. Open the Admin Console for them:
   ```bash
   open "https://keepersecurity.com.au/console"     # AU region
   # or "https://keepersecurity.com/console"        # US/global
   # or "https://keepersecurity.eu/console"         # EU
   ```

2. Narrate to the user:
   > "I just opened the Keeper Admin Console. Sign in with your email + master password + 2FA. When you see the Admin dashboard (Users / Roles / Reports in the left sidebar), come back here and say 'in'."

3. **Wait for "in".** Don't poll, don't run other tools while waiting.

4. After "in":
   > "In the Admin area, click the **Roles** tab (next to Users, Teams, 2FA). You'll see a list of roles. Click into your admin role — usually **Keeper Administrator**. Once inside, click **Enforcement Policies**. A vertical list of categories appears on the left (Login Settings, Two-Factor Authentication, Platform Restriction, etc.). Scroll down and click **Privileged Access Manager** (second from the bottom, above Transfer Account). The right pane switches. At the top: **Keeper Secrets Manager (KSM) → Can create applications and manage secrets**. Make sure that checkbox is ON, then hit **Save**. Say 'on' when saved."

5. **Failure mode**: KSM section greyed out / "not included in your license" / "Permission Denied" — your tier doesn't include Secrets Manager. Fall through to the legacy path (`LEGACY-COMMANDER-PATH.md`), OR note that KSM is a paid add-on the user can enable with Keeper directly.

---

## Phase 4 — Create the KSM Application + Shared Folder + share + token (Vault UI)

Open the Vault (match the region used in Phase 3):
```bash
open "https://keepersecurity.com.au/vault"
```

Narrate the 5 clicks.

### Click 1 — Create the Shared Folder

> "Right-click the folder tree on the left → **New Shared Folder** (NOT 'New Folder' — KSM apps can only see Shared Folders). Name it **`KSM Mac Creds`**. Leave the defaults (Can Manage Users & Records / Can Edit). Click **Create**. Say 'folder' when done."

### Click 2 — Create the KSM Application

> "Click **Secrets Manager** in the left sidebar. You'll see an Applications page. Click **Add Application**. Name it **`<your-name> Mac (kp wrapper)`** — e.g., `<first-name>-mac (kp wrapper)`. Save. Say 'app' when done."

### Click 3 — Share the folder with the app

> "Click into the application. Find the **Folders** tab (or 'Add Folder' button). Add **KSM Mac Creds** → save. Say 'shared' when done."

### Click 4 — Generate the one-time access token

> "Still inside the application, find the **Devices** section / **Add Device** button → click **Generate Access Token**. The token looks like `AU:abc123…`. Copy the whole thing. **Don't paste it here in chat** — come back and say 'token' and I'll open a Terminal window for you to paste it into. Single-use — once consumed, it's dead."

### Click 5 — Hand off

When the user says they have the token:
```bash
~/.claude/skills/keeper-setup/scripts/ksm-init.sh
```

The script opens a Terminal window that prompts for the token, runs `ksm profile init`, auto-discovers the Shared Folder UID via `ksm folder list`, writes it to `~/.keeper/ksm-config`, and closes itself on success. The token never touches chat, shell history, or the process table. After this:
- `kp pass <title>` works for any record in `KSM Mac Creds`
- `kp add <title> <pw>` writes new records to `KSM Mac Creds`

**Why auto-close-on-success?** A live shell prompt after init is a leak trap — voice dictation can accidentally route the user's next sentence (which might contain a real password) into the Terminal window. The auto-close pattern removes that window of risk.

---

## Phase 5 — Verify the wrapper

```bash
~/.claude/skills/keeper-setup/scripts/smoke.sh
kp add "kp-self-test" "round-trip-$$"
[ "$(kp pass "kp-self-test")" = "round-trip-$$" ] && echo "✅ end-to-end works" || echo "❌ mismatch"
# Cleanup
REC_UID=$(ksm --ini-file="$HOME/keeper.ini" secret list 2>/dev/null | awk '$NF=="kp-self-test"{print $1}' | head -1)
[ -n "$REC_UID" ] && ksm --ini-file="$HOME/keeper.ini" secret delete -u "$REC_UID" >/dev/null 2>&1
```

---

## Phase 6 — Legacy Commander-only fallback (when KSM is unavailable)

If Phase 3 hit the license wall, fall through to **`LEGACY-COMMANDER-PATH.md`** (sibling file).

- Same `keeper-commander` install
- `~/bin/kp` set to `scripts/kp-commander-only` (no KSM, plain Commander wrapper)
- Persistent_login + 30d timeout + IP auto-approve dance
- `kp add` is NOT supported on this path — write via Keeper Desktop
- Sessions die when an upstream enforcement policy kicks in; accept the periodic re-auth

---

## Phase 7 — Make Claude on this Mac KNOW to use Keeper

Without this, Claude will keep asking for credentials instead of running `kp pass`.

```bash
# Append the KSM doctrine to whichever CLAUDE.md is loaded for this user.
# Common locations: ~/CLAUDE.md, ~/.claude/CLAUDE.md, or a team-shared kit CLAUDE.md.
CLAUDE_MD_TARGETS=(
    "$HOME/CLAUDE.md"
    "$HOME/.claude/CLAUDE.md"
)
for CLAUDE_MD in "${CLAUDE_MD_TARGETS[@]}"; do
    [ -f "$CLAUDE_MD" ] || continue
    if ! grep -q "kp pass\|kp add" "$CLAUDE_MD"; then
        cat >> "$CLAUDE_MD" <<'EOF'

## Credentials (Keeper, KSM-first)
- KSM-first `kp` wrapper at ~/bin/kp. ALL credentials live in Keeper — never .env, JSON, or shell exports.
- Read: `kp search <term>`, `kp pass <name>`, `kp user <name>`, `kp url <name>`, `kp get <name>`, `kp totp <name>`.
- Write: `kp add <title> <password> [login] [url]` — writes to the user's KSM-shared folder.
- If `kp` is missing or KSM isn't set up, run `/keeper-setup`.
EOF
        echo "Appended KSM doctrine to $CLAUDE_MD"
    fi
done
```

Self-test:
> "Setup done. Ask me 'what's the Stripe API key?' — I should reflexively run `kp search stripe` instead of asking you to paste it."

---

## Phase 8 — Final verification

```bash
keeper version
ksm --version
head -2 "$(command -v kp)" | grep "kp-version"
keeper whoami 2>&1 | grep -E "User:|Account Type:" || echo "(no Commander session — fine, KSM is the primary path)"
ksm --ini-file="$HOME/keeper.ini" profile list | grep '^\s*\*'
ksm --ini-file="$HOME/keeper.ini" folder list | grep . | head -3
grep '^KSM_SF_UID' ~/.keeper/ksm-config
~/.claude/skills/keeper-setup/scripts/smoke.sh
```

All non-error → done.

---

## Troubleshooting (hard-won lessons)

### `ksm secret list` returns empty after a successful init

The application has no folders shared with it. Re-do Phase 4 Click 3 (Vault UI → app → Folders → Add Folder → KSM Mac Creds → Save). Re-run `ksm folder list`.

### "Keyring has no profiles, but a keeper.ini file was found"

The `ksm` CLI sees the keyring extra is installed but the keychain is empty. It ignores `~/keeper.ini` unless told. The `kp` wrapper auto-handles this by passing `--ini-file ~/keeper.ini` when that file exists. To migrate `.ini` → Keychain: generate a fresh one-time token and re-run `ksm-init.sh` (paste the new token into the Terminal it opens).

### "2FA prompt asks for `1`, I typed my password by mistake"

Keeper's interactive 2FA has TWO steps: Step 1 selects the method (`1=TOTP, q=Cancel`); Step 2 takes the 6-digit code. If you type your password at step 1, it errors three times then bails — and the password lands in terminal scrollback. If that happens, clear the scrollback and consider rotating that password.

### Migrating from KeePass `.kdbx` dropped records

KeePass strips shared records and custom-field records (i.e., MCP creds). Use Keeper-native `.keeper` Encrypted Backup format from Keeper Desktop instead.

### Commander session dies inside an hour despite `persistent_login on`

An upstream enforcement policy (managed/MSP-administered account) is overriding your local setting. No local fix. Use the KSM path — KSM tokens don't use the login session, so the policy doesn't apply to them.

### `kp add` fails with "KSM_SF_UID not set"

`~/.keeper/ksm-config` doesn't have a folder UID. Either:
1. Run `ksm-init.sh` again (it auto-discovers), or
2. Manually run `ksm folder list` and set the dir UID in `~/.keeper/ksm-config`.

### `kp pass` returns nothing but the record IS in Keeper

Either:
1. The record is in a folder NOT shared with your KSM app. Move the record into a shared folder, OR share its folder with the app via Vault UI.
2. The Commander session is dead AND the record isn't in KSM.

Debug: `KP_VERBOSE_AUTH=1 KP_SKIP_KSM=1 kp pass <title>` forces Commander path with full auth-prompt output.

---

## What this skill does NOT do

- Migrate credentials FROM Mac → Keeper (use `recipes/audit-mac.sh` + `recipes/import-env-file.py` for that)
- Create shared folders for OTHER users in your org (each user shares into their own KSM app)
- Rotate exposed keys
- Replace `.env` files with `kp pass` calls in code (deliberate per-project refactor)
- Handle SSO accounts where the IdP forbids user-minted application tokens — those fall back to Phase 6

---

## For the org admin (team rollout)

The rollout model is one KSM application per person, on any Keeper Business or Enterprise account. After a team member completes this skill:
- Their KSM application is THEIRS alone — the admin can't read their KSM scope, they can't read the admin's
- For shared team records: create one team Shared Folder, share it with each team member's user, and each member re-shares it into their own KSM application (Phase 4 Click 3) to make those records visible via their `kp pass`
- The per-user-app model is intentional. KSM tokens are sensitive; the only leak vector is a user leaking their own token, which exposes only that user's shared scope
- Token rotation: revoke device + generate new token + re-init. Two clicks + one CLI command

To audit: `keeper audit-report --span week` (Enterprise feature).

---

## Reference

- `REFERENCE.md` — full `ksm` + `kp` + `keeper` command surface
- `LEGACY-COMMANDER-PATH.md` — Commander-only fallback install path
- `CHANGELOG.md` — version history
- `SETUP-PROMPT.md` — paste-into-Claude one-shot install + verify
- `scripts/install.sh` — Phase 1 idempotent installer
- `scripts/ksm-init.sh` — Phase 4 auto-close Terminal for `ksm profile init`
- `scripts/kp` — KSM-first wrapper (source of truth)
- `scripts/kp-commander-only` — legacy fallback
- `scripts/smoke.sh` — verifies skill structure + live install state
- `recipes/audit-mac.sh` — credential discovery on the Mac
- `recipes/import-env-file.py` — import a `.env` as a Keeper record
