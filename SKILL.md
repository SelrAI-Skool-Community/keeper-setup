---
name: keeper-setup
description: "Use when the user says \"connect my Keeper\", \"set up Keeper\", \"install the password manager\", \"I need access to the team passwords\", \"set up credentials\", \"fix the 2FA loop\", \"Keeper keeps logging me out\", \"bring Keeper into Claude Code\", or \"set up KSM\", or when `kp search` fails because `kp` is missing."
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
metadata:
  category: Productivity & Integrations
  tags: [keeper, password-manager, credentials, secrets, security, ksm, autonomous, team]
  audience: Any team member setting up a new Mac, or any developer with a Keeper Business/Enterprise/MSP account they admin
  time-to-complete: 10-15 minutes (most of it is the user clicking through Admin Console + Vault UI once)
  cost-to-user: free (uses an existing Keeper seat; KSM is an enterprise add-on usually included on MSP tier)
  autonomy-bar: "User signs in to Keeper Admin Console once, clicks 5 things in the Vault UI, pastes one one-time token into a Terminal that auto-closes. Everything else — install, config, wrapper deploy, test — runs from Claude silently."
  shipping: "Lives at ~/.claude/skills/keeper-setup/. Distribute to a team via your shared skill repository (e.g. a kit folder synced to GitHub)."
  updated: "2026-08-03 - added the licence-gated KSM check, the shared-config lane, and four common failure modes: silent hang, false session, ambiguous titles, and portable kp doctor resolution."
---

# Keeper Setup — KSM-first⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠

> **The promise:** after this skill runs, the user runs `kp pass example-service` from any shell or Claude session and the value comes back silently while the KSM token remains active.
>
> **The trick:** Keeper Secrets Manager (KSM) uses a long-lived application token that lives in macOS Keychain. It bypasses the regular Keeper login session and any upstream session policy that would otherwise kill `persistent_login` and force re-auth.
>
> **Hard rule:** the user's **master password NEVER enters Claude chat**. Master-password prompts go into a real Terminal window that this skill opens via AppleScript. If you are about to ask the user to type or paste their master password into chat, **STOP** and use the Terminal pattern.

---

## First: choose the access lane

Choose the lane before installing. A licence gate cannot be fixed by repeating configuration steps.

**Fresh KSM application:** use Phases 1 to 5 when the Keeper licence lets this user create a
Secrets Manager application. Verify first with `keeper secrets-manager app list < /dev/null`.

**Managed shared config:** use this lane only when the organisation has already provided an
approved KSM config through Keeper. Do not paste the config into chat.

1. Run `scripts/install.sh` from this skill.
2. Sign in to Keeper Vault or Keeper Desktop and download the supplied `keeper.ini` attachment.
3. Save it as `~/keeper.ini`, run `chmod 600 ~/keeper.ini`, and set `KSM_SF_UID` plus
   `KP_CANONICAL_USER` in `~/.keeper/ksm-config`.
4. Run `scripts/smoke.sh`, then `kp doctor`.

If no shared config has been supplied and the licence check returns:

```
Permission denied: Secrets Manager or Privileged Access Manager is not active on your Keeper License
```

it is a **licence gate, not a permissions or config problem**. Use
`LEGACY-COMMANDER-PATH.md`, or leave the KSM upgrade as an account-owner decision. Ask Claude to
run `kp doctor`, apply the matching lane, and retry the checks.

## Four common traps

These cost hours before they were written down. Every one produces a *confidently wrong*
symptom, which is why they are worth reading before you debug anything.

1. **`keeper` hangs forever instead of failing.** With no live session it prints a hidden
   master-password prompt and waits. In a script or an agent that reads as a network timeout
   or a dead command. **Append `< /dev/null` to every non-interactive `keeper` call**; it then
   fails in about a second with the real reason.

2. **`keeper whoami` is not a session check.** It exits 0 from cached account details while
   real vault reads still demand a password. Code that gates on it reports "signed in", then
   fails later with a misleading error about the record instead of the session. The only
   honest check is attempting an actual record read.

3. **A title lookup returns EMPTY when the title is ambiguous.** Several records sharing one
   title makes `ksm secret notation` fail with *"multiple records match record UID/Title"*, and
   `kp pass <title>` yields nothing at all — which reads as "no access" on a perfectly good
   config. Anything probing a shared record must fall back to resolving by UID.

4. **A record can be named after another record's UID, and be load-bearing.** `kp` resolves by
   title, so an automation may read a record titled `EXAMPLE_RECORD_UID`. It can look like junk
   from a bad `kp add`. Before deleting it, test whether any automation still resolves through it.

Corollary for cleanups: `keeper rm -f` accepts multiple UIDs in its signature, but passing a
long list mangles them into one argument and deletes nothing. Delete one at a time and verify
each with `keeper get` afterwards.

## Single source of truth: one account per user

Each user has exactly **one canonical Keeper account**. Use the regional data centre configured
for the organisation.
Declare it once in `~/.keeper/ksm-config`:

```
KP_CANONICAL_USER="you@yourcompany.com.au"
```

`kp doctor` reads that value and flags any config pointing at a different account. A retired or
migrated account is not a fallback. Archive stale profiles under `~/.keeper/` and never re-add
them as active profiles unless the current Keeper organisation explicitly requires it.

An old account address can survive as a **macOS Keychain account label** or inside a local
blocklist. Confirm whether it is an active login before changing it.

Prefer **slugified** record names such as `example-service--client-secret`. Search by fragment:
`kp search example-service`, not a long prose title.

## Something's wrong? Run `kp doctor` FIRST

`kp doctor` (scripts/kp-doctor.sh) diagnoses the whole stack in one shot — ksm CLI, live KSM
fetch, folder UID, wrapper version, canonical-account check, Commander session (batch-safe,
never prompts), stray old-account configs, keepalive health. Every FAIL prints its exact fix.
Run it before any manual debugging. A dead Commander session is a WARN, not a problem — KSM is the daily path and is
unaffected by the MSP session ceiling.

## Two phases — this SKILL.md is Phase 1 (ACCESS)

Read **START-HERE.md** first when deciding whether this is an Access, Organise, import, legacy,
or package-audit task. It is the routing map that keeps the Keeper work consolidated in this one
skill instead of scattering into overlapping mini-skills.

| Phase | Goal | Where |
|---|---|---|
| **1. Access** | `kp pass record-name` works silently, no 2FA, forever | this SKILL.md |
| **2. Organise** | messy vault → clean folders, tags, record types, colours, filed docs | **ORGANISE-PLAYBOOK.md** |

For a team member setting up their own Keeper: run Phase 1 here, then follow **ORGANISE-PLAYBOOK.md**
\+ **RECORD-TYPES.md** + **COLOURS.md** + **RATE-LIMITS.md**. Those four files are the hard-won
process from the 2026-06-24 build — they exist so nobody re-hits the rate-limit / folder-name /
colour / delete hurdles. **Read RATE-LIMITS.md first** — it's the one that wastes the most time.

---

## Autonomy bar

| User DOES | User DOES NOT |
|---|---|
| Sign in to Keeper Admin Console once (browser) | Open Terminal manually |
| Click 5 things in the Vault UI (create Shared Folder, create KSM Application, share folder with app, generate token, transfer it into the agent-opened terminal) | Paste a master password into Claude chat |
| Paste the one-time KSM token into a Terminal window the skill opens (auto-closes on success) | Type the same code in two places |
| Confirm a couple of yes/no questions in chat (email, seed-from-env?) | Run brew, pipx, keeper, ksm commands manually |
| Restart Claude Code at the end so `~/bin/kp` is on PATH for new shells | Edit `.zshrc`, `.bashrc`, or any config |

If you're about to ask the user to do something not in the left column — pause and check the skill's patterns first.

---

## Trigger phrases (use when)

The skill auto-invokes on any of:
- "Connect my Keeper" / "set up Keeper" / "install the password manager"
- "I need access to the team passwords" / "set up credentials"
- "Fix the 2FA loop" / "my Keeper keeps logging me out" / "Keeper sessions die"
- "Bring Keeper into Claude Code" / "set up KSM"
- The CLAUDE.md doctrine fires `kp search` and `kp` returns command-not-found.

---

## Phase 0 — Preflight (10 seconds)

Detect what's already installed so this skill skips work already done.

Start at the EARLIEST phase whose prerequisite is missing:

```bash
INI_FLAG=()
[ -f "$HOME/keeper.ini" ] && INI_FLAG=(--ini-file="$HOME/keeper.ini")
if ! { command -v keeper >/dev/null 2>&1 && command -v ksm >/dev/null 2>&1 \
       && head -3 "$(command -v kp 2>/dev/null)" 2>/dev/null | grep -q "kp-version: ksm-first"; }; then
    PHASE=1   # CLIs or wrapper missing → full install
elif ! ksm "${INI_FLAG[@]}" profile list 2>/dev/null | grep -q '^\s*\*'; then
    PHASE=3   # installed, but no KSM profile → role enablement + token
elif ! grep -q '^KSM_SF_UID="..*"' "$HOME/.keeper/ksm-config" 2>/dev/null; then
    PHASE=4   # profile live, but no folder UID → re-run ksm-init.sh
else
    PHASE=5   # all wired → just verify
fi
echo "Start at Phase $PHASE"
```

If it says Phase 5 — run `scripts/smoke.sh`; on pass, exit clean, nothing to do.

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

Verify: `keeper version` and `ksm --version` both return values; `head -3 ~/bin/kp` shows the magic sentinel `# kp-version: ksm-first-2026-05-30`.

---

## Phase 2 — Ask for Keeper email (the only thing typed in chat)

Ask the user directly. In Claude, use `AskUserQuestion` when available. In Codex, ask the same
single question in chat or use `request_user_input` if the current mode exposes it.
- Q: "What's the email on your Keeper account?"
- Options: a best-guess based on context, "Other (paste custom)"

**Do NOT ask for the master password here.** Hard rule.

---

## Phase 3 — Enable Secrets Manager on the user's role (Admin Console)

The user must navigate a browser. We narrate the exact path verified on a real setup 2026-05-30.

1. Open the Admin Console for them:
   ```bash
   open "https://keepersecurity.com.au/console"     # AU region
   # or "https://keepersecurity.com/console"        # US/global
   ```

2. Tell the user:
   > "I just opened the Keeper Admin Console. Sign in with your email + master password + 2FA. When you see the Admin dashboard (Users / Roles / Reports in the left sidebar), come back here and say 'in'."

3. **Wait for "in".** Don't poll, don't run other tools while waiting.

4. After "in":
   > "In the Admin area, click the **Roles** tab (next to Users, Teams, 2FA). You'll see a list of roles. Click into your admin role — usually **Keeper Administrator**. Once inside, click **Enforcement Policies**. A vertical list of categories appears on the left (Login Settings, Two-Factor Authentication, Platform Restriction, etc.). Scroll down and click **Privileged Access Manager** (second from the bottom, above Transfer Account). The right pane switches. At the top: **Keeper Secrets Manager (KSM) → Can create applications and manage secrets**. Make sure that checkbox is ON, then hit **Save**. Say 'on' when saved."

5. **Failure mode:** a greyed-out KSM section, "not included in your license", or "Permission
   Denied" means the tier does not include Secrets Manager. Do not loop on the Admin Console.
   Use the managed shared-config lane at the top of this file when an approved config already
   exists, fall back to `LEGACY-COMMANDER-PATH.md`, or leave the paid upgrade decision to the
   account owner.

---

## Phase 4 — Create the KSM Application + Shared Folder + share + token (Vault UI)

Open the Vault:
```bash
open "https://keepersecurity.com.au/vault"
```

Narrate the five clicks below and verify the result after each one.

### Click 1 — Create the Shared Folder

> "Right-click the folder tree on the left → **New Shared Folder** (NOT 'New Folder' — KSM apps can only see Shared Folders). Name it **`KSM Mac Creds`**. Leave the defaults (Can Manage Users & Records / Can Edit). Click **Create**. Say 'folder' when done."

### Click 2 — Create the KSM Application

> "Click **Secrets Manager** in the left sidebar. You'll see an Applications page. Click **Add Application**. Name it **`<your-name> Mac (kp wrapper)`** — e.g., `<first-name>-mac (kp wrapper)`. Save. Say 'app' when done."

### Click 3 — Share the folder with the app

> "Click into the application. Find the **Folders** tab (or 'Add Folder' button). Add **KSM Mac Creds** → save. Say 'shared' when done."

### Click 4 — Generate the one-time access token

> "Still inside the application, find the **Devices** section / **Add Device** button → click **Generate Access Token**. The token looks like `AU:abc123…`. Copy the whole thing. Then come back and paste it as your next message. Single-use — once I consume it, it's dead."

### Click 5 — Hand off

When the user pastes the token:
```bash
~/.claude/skills/keeper-setup/scripts/ksm-init.sh "AU:abc123..."
```

The script runs `ksm profile init` non-interactively, auto-discovers the Shared Folder UID via `ksm folder list`, and writes it to `~/.keeper/ksm-config`. After this:
- `kp pass <title>` works for any record in `KSM Mac Creds`
- `kp add <title> <pw>` writes new records to `KSM Mac Creds`

**Why auto-close-on-success?** A live shell prompt after init is a leak trap. Dictation or a stray paste can route the user's next sentence, which may contain a password, into Terminal.

---

## Phase 5 — Verify the wrapper

```bash
~/.claude/skills/keeper-setup/scripts/smoke.sh
kp add "kp-self-test" "round-trip-$$"
[ "$(kp pass "kp-self-test")" = "round-trip-$$" ] && echo "✅ end-to-end works" || echo "❌ mismatch"
# Cleanup — NOTE: must not be named UID; that variable is read-only in zsh/bash
REC_UID=$(ksm --ini-file="$HOME/keeper.ini" secret list 2>/dev/null | awk '$NF=="kp-self-test"{print $1}' | head -1)
[ -n "$REC_UID" ] && ksm --ini-file="$HOME/keeper.ini" secret delete -u "$REC_UID" >/dev/null 2>&1
```

---

## Phase 6 — Seed the KSM folder from env vars (optional but recommended)

Ask whether to seed the KSM folder from supported environment variables. Run dry mode first so
the user can see record names without exposing values.

```bash
~/.claude/skills/keeper-setup/scripts/seed-folder.sh --dry-run   # for 'dry'
~/.claude/skills/keeper-setup/scripts/seed-folder.sh --yes       # for 'seed'
```

After this, `kp pass stripe-api-key`, `kp pass ghl-api-key`, etc. work silently.

---

## Phase 7 — Legacy Commander-only fallback (when KSM is unavailable)

If Phase 3 hit the license wall, fall through to **`LEGACY-COMMANDER-PATH.md`** (sibling file).

- Same `keeper-commander` install
- `~/bin/kp` set to `scripts/kp-commander-only` (no KSM, plain Commander wrapper)
- Persistent_login + 30d timeout + IP auto-approve dance
- `kp add` is NOT supported on this path — write via Keeper Desktop
- Sessions die when upstream MSP policy kicks in; accept the periodic re-auth

---

## Phase 8 — Make Claude (and Codex) on this Mac KNOW to use Keeper

Without this, the agent will keep asking for credentials instead of running `kp pass`.

```bash
# Append the KSM doctrine to every agent instruction file present on this Mac:
# CLAUDE.md for Claude Code, ~/.codex/AGENTS.md for Codex.
CLAUDE_MD_TARGETS=(
    "$HOME/CLAUDE.md"
    "$HOME/.claude/CLAUDE.md"
    "$HOME/.codex/AGENTS.md"
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
> "Setup done. Ask me for an example service credential. I should run `kp search example-service` instead of asking you to paste it."

---

## Phase 9 — Final verification

```bash
keeper version
ksm --version
head -3 "$(command -v kp)" | grep "kp-version"
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

The `ksm` CLI sees the keyring extra is installed but the keychain is empty. It ignores `~/keeper.ini` unless told. The `kp` wrapper auto-handles this by passing `--ini-file ~/keeper.ini` when that file exists. To migrate `.ini` → Keychain: generate a fresh one-time token and re-run `ksm-init.sh <new-token>`.

### "2FA prompt asks for `1`, I typed my password by mistake"

Keeper's interactive 2FA has TWO steps: Step 1 selects the method (`1=TOTP, q=Cancel`); Step 2 takes the 6-digit code. If you type your password at step 1, it errors three times then bails — and the password lands in terminal scrollback. (Rotating after such a spill is the account owner's call — know the failure mode either way.)

### Migrating from KeePass `.kdbx` dropped records

KeePass strips shared records and custom-field records (i.e., MCP creds). Use Keeper-native `.keeper` Encrypted Backup format from Keeper Desktop instead.

### Commander session dies inside an hour despite `persistent_login on`

Upstream MSP enforcement is overriding your local setting. No local fix. Use the KSM path. KSM tokens bypass the session layer entirely.

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
- Rotate exposed keys. This needs a separate, service-specific rotation plan.
- Replace `.env` files with `kp pass` calls in code (deliberate per-project refactor)
- Handle SSO accounts where the IdP forbids user-minted application tokens — those fall back to Phase 7

---

## For the org admin

After a team member completes this skill:
- Their KSM application is THEIRS alone — you can't read their KSM scope, they can't read yours
- For team shared records, such as an `Example Team` Shared Folder, share that folder with each team member's user. They then share it into their own KSM application in Phase 4, Click 3, so those records are visible through `kp pass`.
- The per-user-app model is intentional. KSM tokens are sensitive; the only leak vector is the user leaking their own token
- Token rotation: revoke device + generate new token + re-init. Two clicks + one CLI command

To audit: `keeper audit-report --span week` (Enterprise feature).

---

## Reference

- `REFERENCE.md` — full `ksm` + `kp` + `keeper` command surface
- `START-HERE.md` — workflow map that keeps Keeper Access, Organise, import, and audit paths together
- `ORGANISE-PLAYBOOK.md` — Phase 2 vault organisation process
- `RATE-LIMITS.md` — Commander batching and throttle discipline
- `RECORD-TYPES.md` — record-type and tag mapping
- `COLOURS.md` — folder colour scheme and `rndir --color` usage
- `CLOSEOUT.md` — final acceptance checklist and closeout commands
- `LEGACY-COMMANDER-PATH.md` — pre-2026-05-30 install path
- `CHANGELOG.md` — version history (2.0.0 KSM-first rewrite)
- `SETUP-PROMPT.md` — paste-into-Claude one-shot install + verify
- `scripts/install.sh` — Phase 1 idempotent installer
- `scripts/ksm-init.sh` — Phase 4 auto-close Terminal for `ksm profile init`
- `scripts/seed-folder.sh` — Phase 6 env→KSM populator (`--dry-run`, `--yes`)
- `scripts/kp` — KSM-first wrapper (source of truth)
- `scripts/kp-commander-only` — legacy fallback preserved verbatim
- `scripts/validate_skill_bundle.py` — package-level consistency checker
- `scripts/smoke.sh` — verifies skill structure + live install state
- `scripts/kp-doctor.sh` — one-shot diagnosis for the installed Keeper stack
- `recipes/audit-mac.sh` — credential discovery on the Mac
- `recipes/import-env-file.py` — import a `.env` as a Keeper record

Router key `sk-9s9ef6` — resolved by the skills index on load.

Router key `sk-18atqw2` — resolved by the skills index on load.
