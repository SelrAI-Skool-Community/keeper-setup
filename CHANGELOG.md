# keeper-setup changelog⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠

## [2.4.0] - 2026-07-08

Team-ready hardening pass.

### Fixed

- Phase 0 preflight logic was inverted: a fresh Mac was told to start at Phase 5 (verify)
  and a fully-installed Mac at Phase 1. Rewritten as a first-broken-prerequisite check.
- Phase 5 verify used `UID=` as a shell variable — `UID` is read-only in zsh/bash, so the
  self-test cleanup errored every run. Renamed to `REC_UID`.
- `kp doctor` check 7 could false-PASS "session alive" when the canonical user was empty.

### Changed

- Canonical account is now per-user config (`KP_CANONICAL_USER` in `~/.keeper/ksm-config`,
  env var override wins) instead of a hardcoded email in `kp-doctor.sh`. `install.sh`
  templates the new key; doctor WARNs when unset.
- Phase 8 doctrine now also lands in `~/.codex/AGENTS.md` — the skill claimed Codex support
  but only wrote CLAUDE.md.
- Scrubbed personal names, personal memory paths, and account emails from SKILL.md,
  REFERENCE.md, RECORD-TYPES.md, and kp-doctor.sh per the publishing firewall.

## [2.3.0] - 2026-07-04

Single-account consolidation + self-diagnosis.

### Added

- `scripts/kp-doctor.sh` + `kp doctor` subcommand: one-shot stack diagnosis (KSM, wrapper,
  canonical account, Commander session, stray configs, keepalive), exact fix per FAIL,
  batch-safe (never prompts), portable (no GNU `timeout` dependency).
- Single-source-of-truth doctrine in SKILL.md: one canonical account per user;
  confirmed legacy configs are archived outside the active profile path.

### Fixed

- The optional Keeper keepalive job runs `keeper sync-down` with stdin closed and
  logs a clear SKIPPED line on a dead Commander session instead of dumping a master-password
  prompt into the log every 4 hours.
- Both `kp` wrapper copies (skill + ~/bin) stay in sync and gained the `doctor` dispatch.

## [2.2.0] - 2026-06-24

Consolidated the Keeper work into one navigable skill package instead of separate remembered
fragments.

### Added

- `START-HERE.md` as the routing map for Access, Organise, import, legacy fallback, and audit work.
- `scripts/validate_skill_bundle.py` as the package-level drift checker for docs, templates, and gotchas.
- `CLOSEOUT.md` as the final acceptance checklist for closing the skill package.

### Changed

- `SKILL.md` now points agents to `START-HERE.md` before choosing a Keeper path.
- `scripts/smoke.sh` now treats the Organise docs and reusable templates as required package files.
- `scripts/validate_skill_bundle.py` now checks its own presence, executable bits, and shell syntax.

### Validation

- Run the commands in `CLOSEOUT.md` before handing this skill to a teammate.

## [2.0.0] - 2026-05-30

KSM-first rewrite. The previous Commander-only install path is preserved as a fallback.

### Background

On a real install, a Keeper Commander session kept dying every few hours despite `persistent_login = on`, 30-day timeout, and IP auto-approve. Migration to a second account produced the same behaviour — both accounts were sub-tenants under the same parent MSP whose role enforcement policy overrides local persistent-login settings. The session-layer fix has a ceiling that local config can't beat. **KSM (Keeper Secrets Manager) bypasses the login session entirely** by using a long-lived application token instead.

### Added

- **KSM-first `~/bin/kp` wrapper** (canonical at `scripts/kp`, magic sentinel `# kp-version: ksm-first-2026-05-30`). Tries `ksm secret notation` first; falls back to `scripts/kp-commander-only` (silent-fail) if the record isn't in KSM-shared scope.
- **`kp add <title> <password> [login] [url]`** — new subcommand that writes records to the KSM-shared folder via `ksm secret add field`. Enables CLI-driven population without Vault UI clicks.
- **`scripts/ksm-init.sh`** — auto-close Terminal wrapper for `ksm profile init <one-time-token>`. Prevents accidental input after the token is consumed.
- **`scripts/seed-folder.sh`** — populates the KSM folder from environment variables already exposed by a local secrets loader. Has `--dry-run` and `--yes` flags.
- **`scripts/kp-commander-only`** — preserved Commander fallback with an optional, user-configured remote host.
- **`LEGACY-COMMANDER-PATH.md`** — fallback documentation for accounts that can't enable KSM (no license, SSO-only, etc.).
- **`~/.keeper/ksm-config`** — per-user config sourced by `kp`. Holds `KSM_SF_UID` (the Shared Folder UID backing the user's KSM application). Auto-populated by `ksm-init.sh`.

### Changed

- **`scripts/install.sh`** — now installs `keeper-commander` AND `pipx install 'keeper-secrets-manager-cli[keyring]'`. Deploys both `kp` and `kp-commander-only` to `~/bin`. Writes the `~/.keeper/ksm-config` template.
- **`scripts/smoke.sh`** — extended with KSM-specific checks: magic sentinel present in deployed `kp`, ksm binary on PATH, `~/.keeper/ksm-config` populated, ksm active profile.
- **`SKILL.md`** — full rewrite around a 9-phase structure. Phases 1-5 are the new KSM-first install. Phase 6 is the optional seed-from-env. Phase 7 is the legacy Commander-only fallback. Phase 8 is the unchanged CLAUDE.md doctrine. Phase 9 is verification.
- **`REFERENCE.md`** — expanded with `ksm` CLI surface area used by `kp`.

### Validation

- `bash scripts/smoke.sh` passes (skill structure + live install state).
- End-to-end round trip verified: `kp add kp-rt-test test-value` then `kp pass kp-rt-test` returns `test-value` silently. Zero master-password prompts, zero 2FA.
- Folder UID discovered by `ksm folder list` matches the `KSM Mac Creds` Shared Folder created in Phase 4 (each install gets its own UID).

### Why this matters

Every team member on a shared Keeper Enterprise seat can run `/keeper-setup` and follow the 5-click Admin Console + Vault UI path to end up with their own KSM application + their own folder + their own token. The skill embeds every lesson from a multi-hour debugging journey so the next person doesn't have to relearn them.

## [1.1.0] - 2026-05-26

Production-grade evidence layer added. Cook to lift kit-doctor score above 4.0.

### Added

- `scripts/smoke.sh`: verifies SKILL.md frontmatter, evidence layer presence, trigger-phrase clause.
- `SETUP-PROMPT.md`: paste-into-Claude install + verify + failure-modes.
- `examples/keeper-setup-session.md`: 3 worked transcripts (standard, edge case, pairs-with handoff).
- This `CHANGELOG.md`.

### Changed

- `SKILL.md` frontmatter description rewritten if previously under 30 words. Added "use when" clause and concrete trigger phrases.

### Validation

- `bash scripts/smoke.sh` passes locally.
- `python3 ~/.claude/skills/kit-doctor/scripts/audit.py ~/.claude/skills/keeper-setup --pretty` returns Promising avg 4.0+.

### Why

kit-doctor flagged evidence=1 (no smoke, no examples, no CHANGELOG). All three are now in place. Differentiation remains at default 3 until external cross-checks supply the data; that lifts the verdict to Production on the next 6h Pass 1 crawl.

### Not touched

- SKILL.md body (operation map, reference content) unchanged.
- Any sister skills or pairs-with references unchanged.

Router key `sk-9s9ef6` — resolved by the skills index on load.
