# Keeper Reference

Quick reference for Keeper Commander, the `ksm` CLI, and the `kp` wrapper. Companion to `SKILL.md`. The `kp` wrapper is **KSM-first** — falls back to Commander only when KSM doesn't have the record.

## KSM CLI surface used by `kp` (the fast path)

| Operation | Command | Notes |
|---|---|---|
| Initialise a profile from a one-time token | `ksm profile init <region>:<base64-token>` | Token is single-use. Profile stored in macOS Keychain if `[keyring]` extra is installed, else `~/keeper.ini`. |
| List profiles | `ksm profile list` | The active profile is marked with `*`. |
| List records visible to this app | `ksm secret list` | Only records inside folders shared with the application. |
| List folders visible to this app | `ksm folder list` | Returns UIDs; first dir UID is what `kp add` uses. |
| Get a single field via notation | `ksm secret notation "keeper://<title-or-uid>/field/password"` | Same notation works for `login`, `url`, `oneTimeCode`. |
| Get full record by title | `ksm secret get -t "<title>"` | |
| Get full record by UID | `ksm secret get --uid "<uid>"` | |
| Add a new record to a Shared Folder | `ksm secret add field --sf <folder-uid> --rt login -t "<title>" "password=..." "login=..." "url=..."` | Used by `kp add`. |
| Delete a record | `ksm secret delete -u <uid>` | |
| Force the ini-file profile when keyring is empty | `ksm --ini-file ~/keeper.ini ...` | The `kp` wrapper does this automatically when `~/keeper.ini` exists. |

## `kp` wrapper

| `kp` command | Action |
|---|---|
| `kp search <term>` | List/find records (KSM first, Commander fallback) |
| `kp pass <title>` | Password value |
| `kp user <title>` | Login value |
| `kp url <title>` | URL value |
| `kp totp <title>` | Current TOTP code |
| `kp get <title>` | Full record |
| `kp list` | All records (KSM first, then Commander section if session alive) |
| `kp add <title> <pw> [login] [url]` | Write a new record to `KSM Mac Creds` (the user's KSM-shared folder) |
| `kp help` | Usage |

Env flags: `KP_VERBOSE_AUTH=1` (show auth prompts for debugging), `KP_SKIP_KSM=1` (force Commander), `KP_NO_FALLBACK=1` (KSM only).

## Capability Matrix

| Capability | CLI command | UI-only? | Risk class |
|---|---|---|---|
| Fetch password / token / URL from a record | `kp pass <name>`, `kp user <name>`, `kp url <name>` | No | safe-read |
| Fetch TOTP 2FA code | `kp totp <name>` | No | safe-read |
| Get full record as JSON | `kp get <name>` | No | safe-read |
| Search records by keyword | `kp search <term>` | No | safe-read |
| List all records | `kp list` | No | safe-read |
| Add a new login record | `keeper record-add --record-type login --title "..." "login=..." "password=..." "url=..."` | No | safe-write |
| Add an SSH key record | `keeper record-add --record-type sshKeys --title "..." "login=..." "keyPair.publicKey=..." "keyPair.privateKey=..."` | No | safe-write |
| Bulk import from JSON | `keeper import --format=json <file>` | No | safe-write |
| Create a user folder | `keeper mkdir -uf "Business/Mac/Other"` | No | safe-write |
| Create a shared folder (Enterprise) | `keeper mkdir -sf "Team Share"` | No | risky (shared state) |
| Share a record with a teammate | `keeper share-record <uid> --email <email> --permission can-view` | No | risky (shared state) |
| Self-destructing share | `keeper record-add ... --self-destruct 5d` | No | safe-write |
| Audit access log (Enterprise) | `keeper audit-report --span week` | No | safe-read |
| Delete a record | `keeper rm -f <uid>` | No | destructive |
| Headless agent fetch (no human login) | Keeper Secrets Manager (KSM) tokens | Partially | safe-read |
| Enable Desktop SSH Agent | Toggle in Keeper Desktop → Settings → SSH Agent | UI-only | safe-write |

## What CANNOT Be Done

- **Transparent SSH via Keeper agent** — Commander's `ssh-agent` is unstable under launchd; Desktop's agent doesn't auto-expose `sshKeys` records. On-disk keys stay primary.
- **Recovery if master password lost AND recovery phrase gone** — Keeper has no admin override. Master password + 24-word recovery phrase are the only paths back in.
- **Eliminate macOS Keychain** — Apple-managed services (Claude Code creds, Keeper Safe Storage itself) must stay in Keychain.
- **Drive Keeper Desktop UI from Claude** — UI features (e.g. marking a key for SSH-agent exposure) can't be automated.
- **Read GitHub Actions secret values via API** — GH Secrets are write-only. Mirror metadata to Keeper as pointers, not values.

## Persistent Login Mechanics

After `keeper this-device persistent_login on`:
- Device-specific key encrypted in macOS Keychain, locked to this Mac
- Logout timeout: 1 hour (auto-resumes on next command via Keychain unlock)
- IP auto-approve ON → no more "new device" emails
- Config: `~/.keeper/config.json`

Persistent login does NOT survive: master password rotation, account-wide logout from Web/Desktop, or revocation by admin.

## Suggested folder structure

```
Business /
├── Mac /                  (this machine's creds)
│   ├── MCP Servers        (env blocks for stdio MCPs)
│   ├── Cloud Accounts     (OAuth clients + per-account tokens)
│   └── Other              (.env files, Keychain mirrors)
├── Server /               (remote server env vars)
├── SSH Keys /             (backed-up private keys, recovery only)
└── Team Share /           (Shared Folder — visible to all team members)
```

Personal records (banking, private accounts) live outside the business tree, never in shared folders.

## Common Failure Modes

| Error | Cause | Fix |
|---|---|---|
| `Error connecting to agent: Connection refused` | Persistent login session timed out | `keeper login <email>` (one master pw entry) |
| `Throttled (attempt N/3)` | Hit Keeper rate-limit | Wait; Commander auto-retries every 60s |
| `command not found: kp` | `~/bin` not on PATH for this shell | `source ~/.zshrc` or restart Claude Code |
| `ls: <folder>: No such folder` | `keeper sync-down` hasn't run yet | `keeper sync-down` |
| `keeper mkdir` hangs waiting for input | Forgot `-uf` (user folder) or `-sf` (shared folder) flag | Re-run with `-uf` |
| `record-add` stores JSON-as-string in keyPair | Used `keyPair={...}` syntax | Use dot-notation: `keyPair.publicKey=...` and `keyPair.privateKey=...` |

## `kp` Wrapper Reference

```
kp search <term>      Find records by name or URL keyword
kp get <uid|title>    Full record as JSON (all fields, secrets included)
kp pass <uid|title>   Password only (pipe to pbcopy or other tools)
kp user <uid|title>   Username only
kp url <uid|title>    URL only
kp totp <uid|title>   Current TOTP code (30s window)
kp list               List all records (uid + title)
kp help               Usage
```

Records can be referenced by 22-char UID OR by title (first match wins).
