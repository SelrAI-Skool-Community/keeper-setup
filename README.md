# Keeper Setup⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠

This skill sets up Keeper for Claude Code or Codex on a Mac. It installs Keeper Commander and
Keeper Secrets Manager, adds the `kp` helper, stores the KSM profile safely, and verifies that
credential lookups work without putting a master password into chat.

It is for Keeper Business, Enterprise, or MSP users who want reliable command-line access to
their own vault or approved team records. KSM needs to be included in the Keeper licence. When
it is not available, the skill includes a Commander-only fallback.

## One-prompt install

Open this folder in Claude Code or Codex and paste:

```text
Install Keeper from this skill. Read START-HERE.md, choose the correct access lane, run the
installer, and finish every verification in CLOSEOUT.md. Never ask me to paste my Keeper master
password or a KSM token into chat. Use a real Terminal for secret entry. If a check fails, diagnose
it with kp doctor, fix the documented cause, and retry until the package and access checks pass.
```

The agent handles the install and checks. You may need to sign in to Keeper once, approve the
device, or enable KSM in the Keeper Admin Console.

## If it fails

Ask Claude to run `kp doctor`, read the matching failure in `SKILL.md`, apply the fix, and retry.
If the Keeper licence does not include KSM, use the managed shared-config lane when your
organisation supplied an approved config. Otherwise use `LEGACY-COMMANDER-PATH.md`.

Router key `sk-9s9ef6` - resolved by the skills index on load.
