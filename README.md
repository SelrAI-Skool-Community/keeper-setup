# keeper-setup

Set up the Keeper password manager so Claude can use your logins safely, without ever seeing your master password.

After the 10-minute guided install, Claude fetches any credential it needs with one command (`kp pass stripe-api-key`) and the value comes back silently. No 2FA prompts. No "session expired". No pasting API keys into chat ever again.

## Who it's for

Business owners and teams using Claude Code who have a Keeper Business account. No technical background needed. You sign in once, click 5 things in the Keeper website, and Claude does the rest.

## Install

1. Copy this folder to `~/.claude/skills/keeper-setup/` on your Mac.
2. Open Claude Code and paste the prompt from `SETUP-PROMPT.md`.
3. When it verifies clean, say **"set up Keeper"** and follow along.

If anything fails during the install, ask Claude to retry — the scripts install missing pieces and pick up where they left off.

## What's inside

| File | What it does |
|---|---|
| `SKILL.md` | The full guided install Claude follows |
| `SETUP-PROMPT.md` | One-paste install + verify prompt |
| `REFERENCE.md` | Every `kp` and `ksm` command, plus failure fixes |
| `LEGACY-COMMANDER-PATH.md` | Fallback for accounts without Secrets Manager |
| `scripts/` | Installer, token setup, the `kp` wrapper, smoke test |
| `recipes/` | Find stray credentials on your Mac, import `.env` files |

## The one safety rule

Your master password never enters Claude chat. Anything that needs it happens in a real Terminal window that closes itself when done.

Made by Selr AI
