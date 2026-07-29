# keeper-setup changelog

## [1.1.0] - 2026-07-30

### Changed

- **`scripts/ksm-init.sh` no longer accepts the one-time token as a command-line argument** — argv leaks into shell history and the process table. Token input is now the auto-close Terminal prompt (default) or `--stdin` (pipe it in). Passing a token as an argument is refused with a pointer to the safe paths.
- `SKILL.md` Phase 4 updated to match: the token is pasted into the agent-opened Terminal window, never into chat.
- Background and troubleshooting notes generalised for distribution outside the original install environment.

## [1.0.0] - 2026-06-10

First public release. KSM-first install with a Commander-only fallback.

### Background

On managed (MSP-administered) Keeper accounts, a parent tenant's role enforcement policy can override local persistent-login settings — Commander sessions die every few hours despite `persistent_login = on`, a 30-day timeout, and IP auto-approve. That's a ceiling local config can't beat. **KSM (Keeper Secrets Manager) sidesteps the login session entirely** by using a long-lived application token instead. That's why this skill is KSM-first.

### Included

- **KSM-first `~/bin/kp` wrapper** (canonical at `scripts/kp`, magic sentinel `# kp-version: ksm-first-2026-05-30`). Tries `ksm secret notation` first; falls back to `scripts/kp-commander-only` (silent-fail) if the record isn't in KSM-shared scope.
- **`kp add <title> <password> [login] [url]`** — writes records to the KSM-shared folder via `ksm secret add field`. Enables CLI-driven population without Vault UI clicks.
- **`scripts/install.sh`** — idempotent installer for `keeper-commander` AND `pipx install 'keeper-secrets-manager-cli[keyring]'`. Deploys both `kp` and `kp-commander-only` to `~/bin`. Writes the `~/.keeper/ksm-config` template.
- **`scripts/ksm-init.sh`** — auto-close Terminal wrapper for `ksm profile init`. Prevents accidental dictation into a live shell prompt after the token is consumed.
- **`scripts/kp-commander-only`** — Commander-only wrapper for the legacy path.
- **`scripts/smoke.sh`** — verifies skill structure plus live install state (sentinel present in deployed `kp`, ksm binary on PATH, `~/.keeper/ksm-config` populated, ksm active profile).
- **`LEGACY-COMMANDER-PATH.md`** — fallback documentation for accounts that can't enable KSM (no license, SSO-only, etc.).
- **`~/.keeper/ksm-config`** — per-user config sourced by `kp`. Holds `KSM_SF_UID` (the Shared Folder UID backing the user's KSM application). Auto-populated by `ksm-init.sh`.
- **`recipes/audit-mac.sh`** + **`recipes/import-env-file.py`** — find credential files on a Mac and import a `.env` into Keeper as one record.

### Validation

- `bash scripts/smoke.sh` passes (skill structure + live install state).
- End-to-end round trip verified: `kp add kp-rt-test test-value` then `kp pass kp-rt-test` returns `test-value` silently. Zero master-password prompts, zero 2FA.
- Folder UID discovered by `ksm folder list` matches the `KSM Mac Creds` Shared Folder created in Phase 4 (each install gets its own UID).

### Why this matters

Every team member on a Keeper Business or Enterprise seat can run `/keeper-setup` and follow the 5-click Admin Console + Vault UI path to end up with their own KSM application + their own folder + their own token. The skill embeds every hard-won debugging lesson so the next person doesn't have to relearn them.
