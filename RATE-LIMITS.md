# Keeper Commander — rate-limit discipline (HARD RULE)⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠

> The mistake this prevents: firing many separate `keeper <cmd>` subprocess calls in a
> session. Each fresh `keeper` process does its own login; volume trips Keeper's server
> rate-limiter, which then makes persistent-login token auth FAIL → every command falls
> back to a master-password prompt and HANGS. Whole session becomes unusable for ~15-60 min.
> (Lesson 2026-06-24 after a colour/delete batch session got throttled mid-way.)

## Rules
1. **ONE `keeper shell` session per batch.** Put ALL write commands (rm, mv, rndir, record-update,
   upload-attachment, mkdir) into a single command file and run `keeper shell < file` (or
   `keeper run-batch file`). NEVER loop `subprocess.run(["keeper", ...])` per item. Exception:
   for output-heavy reads such as `tree`, pipe commands through `subprocess.run(input=...)`
   instead of redirecting a file, because large `tree` output can hang.
2. **Persistent login must be ON** before batching: `this-device persistent-login on` +
   `this-device register` + `this-device timeout 1440` (set once, interactively).
3. **A master-password prompt mid-session = you are rate-limited.** Do NOT retry in a loop
   (each attempt resets the cooldown). Back off ≥15 min, then run ONE batch.
4. **Cap probing.** Don't sprinkle `whoami`/`ls`/`--help` checks between operations — each is
   a login. Check auth ONCE at the start of a batch, then run everything.
5. **Reading also costs logins.** Use `tree`/`ls`/`get` sparingly and inside the SAME shell
   session as the writes when possible; prefer KSM (`kp`/`ksm`, separate keyless auth) for
   reads of records still in the KSM Mac Creds shared folder.
6. **KSM can't see user folders.** Once a record is `mv`'d out of the KSM Mac Creds shared
   folder into a user folder (Companies/Personal), KSM (`kp`/`ksm`) returns access_denied for
   it — reads AND deletes must go through Commander. Plan deletes/edits before moving, or batch
   them via Commander.

## Pattern (correct)
```python
cmds = ["rm <uid>", "y", "rndir -q --color blue \"Companies/X\"", ...]   # everything
open("batch.kc","w").write("\n".join(cmds)+"\nquit\n")
subprocess.run(["bash","-lc",'keeper shell < batch.kc'], timeout=300)    # ONE session
```

Router key `sk-9s9ef6` — resolved by the skills index on load.
