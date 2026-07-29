# Worked example: keeper-setup session

A condensed transcript of an example install flow.

## Example 1: Standard KSM-first install

```
User: set up Keeper

Claude: [invokes /keeper-setup, runs Phase 0 preflight]
Nothing installed yet — starting at Phase 1.
[runs scripts/install.sh — installs keeper-commander, ksm CLI, deploys ~/bin/kp]
What's the email on your Keeper account?

User: owner@example.com

Claude: I just opened the Keeper Admin Console. Sign in with your email +
master password + 2FA. When you see the Admin dashboard, say 'in'.

User: in

Claude: [narrates Roles → Enforcement Policies → Privileged Access Manager →
enable KSM checkbox]

User: on

Claude: [opens the Vault, narrates the 5 clicks: Shared Folder, KSM Application,
share folder with app, generate token — token goes in a Terminal, never chat]

User: token

Claude: [runs scripts/ksm-init.sh — a Terminal window opens, the user pastes
the one-time token there, the window auto-closes on success; profile lands in
Keychain, folder UID written to ~/.keeper/ksm-config]
[runs scripts/smoke.sh — SMOKE PASS]
[round-trip test: kp add kp-self-test → kp pass kp-self-test → match → cleanup]

Done. `kp pass <record>` now works silently from any shell. No 2FA, no master
password, ever.
```

## Example 2: License wall (edge case)

```
User: set up Keeper

Claude: [Phase 3 — user reports the KSM checkbox is greyed out:
"not included in your license"]

Your tier doesn't include Secrets Manager. Falling back to the legacy
Commander-only path (LEGACY-COMMANDER-PATH.md). You'll get the same kp
commands, but sessions re-auth periodically.

[installs kp-commander-only as ~/bin/kp, opens a Terminal for the one
interactive keeper login — master password never enters chat]
```

## Example 3: Already installed (idempotent re-run)

```
User: connect my Keeper

Claude: [Phase 0 preflight — keeper, ksm, kp sentinel, active profile,
populated ksm-config all present]
[runs scripts/smoke.sh — SMOKE PASS]

Already set up. `kp pass <record>` is live. Nothing to do.
```
