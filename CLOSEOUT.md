# Keeper Skill Closeout⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠

This is the final acceptance checklist for the `keeper-setup` skill package.

## Closed scope

- One canonical Keeper skill package exists: `keeper-setup`.
- Access work routes through `SKILL.md`.
- Organise work routes through `ORGANISE-PLAYBOOK.md`.
- Team routing starts at `START-HERE.md`.
- Commander rate-limit discipline lives in `RATE-LIMITS.md`.
- Record types and tags live in `RECORD-TYPES.md`.
- Folder colours live in `COLOURS.md`.
- Reusable setup, access, diagnosis, and validation scripts live in `scripts/`.
- Package drift is checked by `scripts/validate_skill_bundle.py`.
- Live install smoke checks are run by `scripts/smoke.sh`.

## Closeout commands

Run these after the skill is installed at `~/.claude/skills/keeper-setup`:

```bash
python3 ~/.claude/skills/keeper-setup/scripts/validate_skill_bundle.py
bash ~/.claude/skills/keeper-setup/scripts/smoke.sh
python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py ~/.claude/skills/keeper-setup
```

Pass criteria:

- Bundle validator prints `keeper-setup bundle validation PASS`.
- Smoke test prints `SMOKE PASS`.
- Skill validator prints `Skill is valid!`.

## What is outside this skill

- Filing a real vault still needs a live Keeper Commander session when records have moved outside
  KSM scope.
- Browser re-auth for unrelated services is not part of this skill.
- Actual secret values, identity numbers, cards, and documents never belong in this package.

## Do not reopen unless

- Keeper changes Commander or KSM CLI syntax.
- A teammate hits a documented gotcha despite following `START-HERE.md`.
- A validator catches drift.
- A new Keeper workflow has a separate trigger, separate user, and separate validation path.

Router key `sk-9s9ef6` — resolved by the skills index on load.
