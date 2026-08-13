# Keeper Skill Start Here⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠

Use this file to choose the right Keeper workflow. Keep one canonical skill package:
`keeper-setup`. Do not fork new Keeper skills unless the work has a genuinely separate trigger,
separate user, and separate validation path.

## Choose the path

| Need | Use | Then read |
|---|---|---|
| Make `kp pass record-name` work on a Mac | `SKILL.md` Phase 1-9 | `REFERENCE.md`, `SETUP-PROMPT.md` |
| Onboard a team member to Keeper access | `SKILL.md` + `SETUP-PROMPT.md` | `LEGACY-COMMANDER-PATH.md` only if KSM is unavailable |
| Clean up a messy vault | `ORGANISE-PLAYBOOK.md` | `RATE-LIMITS.md`, `RECORD-TYPES.md`, `COLOURS.md` |
| Move records, tag, retype, colour, or upload docs | `ORGANISE-PLAYBOOK.md` | Build a batch from live vault output and follow `RATE-LIMITS.md` |
| Import local `.env` or Mac credential files | `recipes/audit-mac.sh`, `recipes/import-env-file.py` | Never print or commit values |
| Audit the skill package itself | `scripts/validate_skill_bundle.py` then `scripts/smoke.sh` | Fix drift before using the skill with a teammate |
| Close the skill package | `CLOSEOUT.md` | Run the closeout commands before marking done |

## Canonical file roles

- `SKILL.md` is the Access workflow: install Commander, KSM, and the KSM-first `kp` wrapper.
- `START-HERE.md` is the routing map: choose the workflow and avoid duplicate Keeper skills.
- `ORGANISE-PLAYBOOK.md` is the Organise workflow: folders, tags, record types, colours, docs.
- `RATE-LIMITS.md` is the batching rulebook: read it before any Commander write batch.
- `RECORD-TYPES.md` is the type and tag map: stop using `login` for everything.
- `COLOURS.md` is the folder colour scheme and `rndir --color` command.
- `REFERENCE.md` is the command surface for `kp`, `ksm`, and Keeper Commander.
- `LEGACY-COMMANDER-PATH.md` is fallback only when KSM cannot be enabled.
- `CLOSEOUT.md` is the final acceptance checklist.
- `scripts/install.sh`, `scripts/ksm-init.sh`, and `scripts/seed-folder.sh` handle setup.
- `scripts/kp`, `scripts/kp-commander-only`, and `scripts/kp-doctor.sh` handle daily access and diagnosis.
- Build organisation batches from current `keeper tree` and `keeper get` output. Never reuse another vault's paths or record identifiers.
- `scripts/validate_skill_bundle.py` checks this package stays internally consistent.
- `scripts/smoke.sh` checks the package and, when run on a configured Mac, the live install.

## Non-negotiables

- Never ask for, print, store, or commit a Keeper master password, API key, TFN, card number, or
  other secret value.
- Use KSM for fast reads only while records live in the KSM shared folder. Once moved into user
  folders, use Keeper Commander.
- Batch Commander writes in one shell session. Do not loop one `keeper` process per item.
- Attach files by record UID, not title.
- Use plain hyphens in record titles. Avoid em dashes in titles because name-based `kp` lookups
  can break.
- Verify real output before calling the workflow done: `validate_skill_bundle.py`, `smoke.sh`,
  screenshots for colours, and download checks for file attachments.

## Normal order for a full vault project

1. Run Access: `SKILL.md` until `kp pass record-name` works.
2. Confirm Commander persistent login before Organise.
3. Read `RATE-LIMITS.md`.
4. Build folders from live Keeper tree output, not memory.
5. Move and tag records.
6. Retype records only when the source value is available and can be set safely.
7. Apply colours in a paced Commander batch.
8. Create file records, wait for sync, then attach by UID.
9. Verify in the Keeper app and with attachment download checks.
10. Run the closeout commands in `CLOSEOUT.md` before handing to the team.

Router key `sk-9s9ef6` — resolved by the skills index on load.
