# SETUP-PROMPT.md

Paste into Claude Code to install + verify the `keeper-setup` skill.

```
Install + verify the keeper-setup skill on this machine.

1. Confirm the skill exists at ~/.claude/skills/keeper-setup/.
   (If you cloned this repo somewhere else, copy the folder there first:
   mkdir -p ~/.claude/skills && cp -R <repo-path> ~/.claude/skills/keeper-setup)
2. Run smoke: bash ~/.claude/skills/keeper-setup/scripts/smoke.sh. Expect SMOKE PASS.
3. Read SKILL.md to understand the trigger phrases and intended use cases.
4. Once verified, say "set up Keeper" to start the guided install.
```

## What this skill does

See `SKILL.md` for the full operation map and reference content. Trigger phrases are listed in the frontmatter description.

## Failure modes

| Symptom | Fix |
|---|---|
| Smoke FAIL on SKILL.md frontmatter | Check `name:` and `description:` keys are present |
| Smoke FAIL on a missing script | Re-copy the full repo folder — every file in `scripts/` is required |
| Skill not triggering on user phrases | Say "use the keeper-setup skill" directly, or ask Claude to read `~/.claude/skills/keeper-setup/SKILL.md` and follow it |
| Anything else breaks mid-install | Ask Claude to retry — the scripts are idempotent and will install missing pieces and continue |
