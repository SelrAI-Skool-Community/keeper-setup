# Keeper Setup⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠

This skill sets up Keeper for Claude Code or Codex on a Mac. It installs Keeper Commander and
Keeper Secrets Manager, adds the `kp` helper, stores the KSM profile safely, and verifies that
credential lookups work without putting a master password into chat.

It is for Keeper Business, Enterprise, or MSP users who want reliable command-line access to
their own vault or approved team records. KSM needs to be included in the Keeper licence. When
it is not available, the skill includes a Commander-only fallback.

## One-prompt install

Open a new Claude Code session, anywhere, and paste:

```text
Install the Keeper setup skill for me, following the install steps in https://github.com/luke-heka/keeper-setup
```

That is the whole install. Claude clones this repo, copies the skill into
`~/.claude/skills/keeper-setup/`, runs the installer, and works through the verification steps.

Claude is told, by the skill itself, never to ask you to paste your Keeper master password or a
KSM token into chat. Secret entry happens in a real Terminal window. If a check fails it runs
`kp doctor`, reads the matching failure, applies the fix and retries.

### Doing it by hand instead

1. Clone this repo and copy the folder to `~/.claude/skills/keeper-setup/`.
2. Run `bash scripts/install.sh`.
3. Read `START-HERE.md` and follow the lane it routes you to.
4. Finish every verification in `CLOSEOUT.md`.
5. Restart Claude Code so the skill loads.

You know it worked when `kp pass <record-name>` returns a value in any shell.

The agent handles the install and checks. You may need to sign in to Keeper once, approve the
device, or enable KSM in the Keeper Admin Console.

## If it fails

Ask Claude to run `kp doctor`, read the matching failure in `SKILL.md`, apply the fix, and retry.
If the Keeper licence does not include KSM, use the managed shared-config lane when your
organisation supplied an approved config. Otherwise use `LEGACY-COMMANDER-PATH.md`.

Router key `sk-9s9ef6` - resolved by the skills index on load.
