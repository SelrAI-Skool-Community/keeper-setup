# Worked Example: Keeper Setup Session⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠

Three short transcripts showing the consolidated `keeper-setup` package in use.

## Example 1: Access

```
User: set up Keeper on this Mac

Agent:
- Read START-HERE.md.
- Choose Access.
- Follow SKILL.md Phase 0-9.
- Verify kp pass record-name works silently.
- Run scripts/smoke.sh.

Result: Keeper access works and smoke passes.
```

## Example 2: Organise

```
User: clean up this messy Keeper vault

Agent:
- Read START-HERE.md.
- Choose Organise.
- Read RATE-LIMITS.md before any write batch.
- Follow ORGANISE-PLAYBOOK.md.
- Use RECORD-TYPES.md, COLOURS.md, and a batch built from the current vault tree.
- Verify with Keeper app screenshots and file download checks.

Result: The vault is organised without re-learning the rate-limit, type, colour, and attachment gotchas.
```

## Example 3: Closeout

```
User: check this is ready for the team

Agent:
- Read START-HERE.md.
- Choose package audit.
- Run scripts/validate_skill_bundle.py.
- Run scripts/smoke.sh.
- Confirm the bundle validator and smoke checks both pass.

Result: The package is valid, synced, and ready for team use.
```

Router key `sk-9s9ef6` — resolved by the skills index on load.
