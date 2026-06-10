# Legacy Commander-only path (fallback when KSM isn't available)

The primary `/keeper-setup` flow is **KSM-first** (see `SKILL.md`). This document covers the **fallback** for users on Keeper Enterprise tiers that don't include Secrets Manager, or on SSO accounts where KSM tokens can't be minted by the user.

## When to use this path

- Admin Console → Roles → Enforcement Policies → Privileged Access Manager shows `Keeper Secrets Manager (KSM) → Can create applications and manage secrets` **greyed out** with a "not included in your license" / "Permission Denied" message.
- The user's account is SSO-only and the org's identity provider doesn't allow user-minted application tokens.
- The user explicitly opts into the legacy path (e.g., they only need ad-hoc credential lookups, not Claude Code automation, and don't want to pay for KSM).

If neither blocker applies — **use the KSM path in SKILL.md.** KSM is faster, prompt-free, and survives MSP enforcement policies that kill Commander sessions.

## How the legacy path differs from KSM

| | KSM-first (primary) | Commander-only (legacy) |
|---|---|---|
| Auth artifact | Long-lived application token | Master-password session + device approval |
| 2FA frequency on `kp pass` | Never (after init) | Whenever session lapses (hours to days; sub-hour if MSP policy is aggressive) |
| Storage of secret material | KSM Shared Folder shared with one app | User's full vault, all folders |
| Read scope | Only records in folders shared with this app | Whole vault |
| Write via `kp` | `kp add <title> <pw>` (via `ksm secret add field`) | Not supported — write via Keeper Desktop or Commander shell |
| Failure mode when session dies | N/A — token doesn't die | Silent fail + exit 1 (via `kp-commander-only`'s wrapper logic) |
| License tier | Requires Secrets Manager add-on enabled at role level | Any Keeper Business/Enterprise/MSP account |

## Install (legacy)

```bash
# 1. Install Commander
brew install keeper-commander

# 2. Install kp-commander-only wrapper as ~/bin/kp
mkdir -p ~/bin
cp ~/.claude/skills/keeper-setup/scripts/kp-commander-only ~/bin/kp
chmod +x ~/bin/kp

# 3. PATH (if not already done)
grep -q 'export PATH="$HOME/bin' ~/.zshrc || echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc

# 4. Interactive login (master password + 2FA in a real Terminal — never via Claude chat)
osascript <<'OSA'
tell application "Terminal"
    activate
    do script "keeper login <your-email> && keeper this-device persistent_login on && keeper this-device ip_auto_approve on && keeper this-device timeout 30d && keeper sync-down && echo 'DONE'"
end tell
OSA
```

## Operations

- `kp search <term>`, `kp pass <title>`, `kp user <title>`, `kp url <title>`, `kp get <title>`, `kp totp <title>`, `kp list` — same surface as KSM path.
- `kp add <title> <pw>` — **NOT supported** on legacy. Add records via Keeper Desktop or `keeper shell` → `record-add`.

## When the legacy session keeps dying

If `kp pass` keeps tripping 2FA every few hours despite `persistent_login on` + 30-day timeout, the account is policy-locked by an upstream MSP. The options are:

1. Have the upstream MSP relax the role's `Disable Stay Logged In` policy. Practical hit-rate: low.
2. Move the account to a Keeper Business/Enterprise tier you control end-to-end (separate vault, separate billing, separate Admin Console). Migration via `.keeper` encrypted export from Desktop, NOT `.kdbx` — KeePass format strips shared records and custom fields.
3. **Upgrade to KSM.** This is the documented "primary path" answer. See SKILL.md.

## Why this file exists

KSM was promoted to the primary path after repeated Commander session failures on accounts where a parent MSP's role enforcement policy overrides local `persistent_login` settings. Migration to a sibling account under the same MSP showed the same behaviour. KSM was the durable fix — its token-based auth bypasses the regular login session entirely. The old Commander-based install path is preserved here as the fallback — it remains the right answer for accounts that can't enable KSM (no license, SSO-only, etc.).
