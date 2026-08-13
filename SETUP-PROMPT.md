# Keeper Setup Prompt⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠

Paste into Claude Code or Codex when installing, auditing, or closing the `keeper-setup` skill.

```
Install, verify, and close out the keeper-setup skill on this machine.

1. Confirm the skill exists at ~/.claude/skills/keeper-setup/.
2. Read START-HERE.md and choose the right path: Access, Organise, import, legacy fallback, or audit.
3. For Access, follow SKILL.md until kp pass record-name works.
4. For Organise, read RATE-LIMITS.md before running any Keeper Commander write batch.
5. Run the closeout commands in CLOSEOUT.md.
6. Once every closeout command passes, the skill package is ready for team use.
```

## What this skill does

See `START-HERE.md` first. It routes to the right file and keeps Keeper work consolidated in one
skill package.

## Failure modes

| Symptom | Fix |
|---|---|
| Smoke FAIL on SKILL.md frontmatter | Check `name:` and `description:` keys are present |
| Bundle validator FAIL | Fix the missing file, stale reference, executable bit, or syntax error it names |
| Smoke FAIL on package files | Restore the missing document or retained script named in the failure |
| Skill not triggering on user phrases | Improve the frontmatter description trigger phrases |
| Keeper write batch hangs | Stop retries, read RATE-LIMITS.md, wait for cooldown, and rerun one batch |

## Closeout

Run:

```bash
python3 ~/.claude/skills/keeper-setup/scripts/validate_skill_bundle.py
bash ~/.claude/skills/keeper-setup/scripts/smoke.sh
python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py ~/.claude/skills/keeper-setup
```

Router key `sk-9s9ef6` — resolved by the skills index on load.
