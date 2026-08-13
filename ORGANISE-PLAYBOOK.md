# Keeper Vault Organisation — the team handover playbook⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠

> **What this is:** the repeatable process to take a messy Keeper vault (everything dumped in
> as `login` records) and turn it into a clean, colour-coded, tagged, properly-typed structure.
> Phase 1 (keeper-setup SKILL.md) gets you ACCESS (`kp` works). This is Phase 2: ORGANISE.
>
> This playbook captures the failure modes that tend to appear during a full vault build. Read
> the GOTCHAS section first so the same vault, rate-limit, and attachment errors do not repeat.

If the task is not clearly a vault-organisation task, start with **START-HERE.md**. It routes
Access, Organise, import, legacy fallback, and package-audit work without creating duplicate
Keeper skills.

## Prerequisites (do these once, in order)
1. Keeper Commander installed + logged in: `keeper login <you>@<domain>`.
2. **Persistent login ON** (this is what lets scripts run without password prompts). In
   `keeper shell`: `this-device persistent-login on` → `this-device register` →
   `this-device timeout 1440`. Verify: `this-device` shows `Persistent Login: ON`.
3. Read **RATE-LIMITS.md** — the #1 thing that wrecks an org session is firing many separate
   `keeper` commands. ALWAYS batch into ONE `keeper shell` session.

## The target structure (adapt entity names per person)
```
Companies/
  <Each legal entity>/        ← one folder per company/trust, e.g. "Acme Pty Ltd"
    Identifiers/              ← ABN, ACN, ASIC keys, logins tied to the entity
    Tax & BAS/                ← TFN, BAS lodgements, ATO docs
    Banking/                  ← bank accounts (bankAccount records)
    Insurance & Licences/     ← policies, certificates
    People/                   ← directors, employees, contacts
    Registration/             ← registration certs, constitutions, deeds
    Documents/                ← everything else for that entity
<Personal Folder>/            ← the owner's personal folder (existing top-level)
  IDs & Government/           ← TFN, licence, passport, Medicare-adjacent IDs
  Banking & Cards/            ← personal bank accounts + payment cards
  Health/                     ← Medicare, health insurance
  Qualifications/             ← USI, certs, training records
  Documents/                  ← misc personal docs
```

## The 5 steps (each is ONE keeper-shell batch, paced)

**Step 1 — folders.** Create the tree: `mkdir --user-folder "Companies/<Entity>/Identifiers"` etc.
GROUND FIRST: run `ls -l -f` and `tree "Companies"` to see EXISTING folder names — match them
exactly, don't invent variants. Creating `Example Pty Ltd` when `Example Holdings` is the real
folder makes duplicates. For large `tree` output, send the command through stdin from Python rather than
`keeper shell < file`. One session, all mkdirs.

**Step 2 — file records into folders + tag.** For each record: `mv <uid> "<folder>"` then
`record-update -r <uid> --tag <entity> --tag <category>`. Tags: entity slug (`acme`, `personal`)
+ category (`tax`, `banking`, `identifier`, `card`, `licence`, `insurance`, `api-key`, `login`).
Do mv + tag ONLY here (no field edits — see GOTCHA on shell quoting). ONE session.

**Step 3 — record types.** Retype from generic `login` to the right type (see RECORD-TYPES.md):
`record-update -r <uid> -rt <type> "secret.TFN=<value>"`. CRITICAL: re-set the value into the new
type's field FROM SOURCE, because retyping to a type without a `password` field drops the old
value. Only retype when you re-supply the value. ONE session. (This step is optional polish —
folders + tags already make the vault usable.)

**Step 4 — colours.** See COLOURS.md. CLI only: `rndir -q --color <c> "<folder path>"`. Scheme:
each entity a DISTINCT colour, every subfolder coloured by CATEGORY (Banking=green everywhere,
Identifiers=blue, Tax=orange, Insurance=yellow, People=red, Documents/Registration=gray). PACE it:
~10 folders per session, 10-15s pause between, resumable.

**Step 5 — documents.** Upload PDFs/scans as `file` records into the right folder. TWO passes
(record and attach are separate — the record must sync before it can be attached to):
1. Create all records: `record-add -rt file -t "<title>" --folder "<folder>"`.
2. Then attach by **UID** (NOT title — see GOTCHA): `upload-attachment <UID> --file <path>`.
Heaviest step — pace ~8-10/session, 12-15s pause, resumable, runs in background. Verify with
`download-attachment <UID> --out-dir` (the file lives in the record's `fileRef` field value).

**Always finish by VERIFYING WITH EYES** — screenshot the Keeper desktop app and look at the
coloured folders + filed records. Exit codes lie; a screenshot doesn't.

## GOTCHAS (every one of these cost real time — read before starting)
- **Rate-limit is the boss fight.** Many separate `keeper` calls → server throttles the account
  → persistent-login token auth fails → every command falls back to a master-password prompt and
  HANGS. Cure = ONE session per batch + genuine quiet time (≥30 min of NO keeper activity).
  Retrying during throttle KEEPS IT HOT. Build prompt-detection into scripts so they abort in
  seconds, not 600s. (Full rule: RATE-LIMITS.md.)
- **A "master password" prompt mid-batch usually means rate-limited, NOT that login dropped.**
  Probe with one read (`ls`); if it says "Successfully authenticated with Persistent Login",
  auth is fine and you're just throttled — wait, don't re-login.
- **Deletes are a `[y/n]` confirmation, not a password gate.** `rm <uid>` → answer `y`. (During a
  throttle it can *look* like a password prompt — that's the throttle, not a real gate.)
- **KSM (`kp`/`ksm`) only sees the "KSM Mac Creds" shared folder.** The moment you `mv` a record
  into a user folder (Companies/Personal), `kp`/`ksm` returns access_denied for it — reads AND
  deletes must then go through Commander. So if you seeded records via `kp add`, do any KSM-based
  cleanup BEFORE moving them.
- **Folder colours are CLI-only** (`rndir --color`). The app's folder right-click menu has NO
  colour option — it's hidden in the folder detail-panel's ⋮ → Change Color (manual, one folder
  at a time). Always do colours via the CLI.
- **`keeper shell` mangles quoted field VALUES with spaces** (e.g. `"text.Person=Acme Pty Ltd"`).
  mv + colour + tag work fine quoted; field-setting with spaces does not. Set space-containing
  fields via direct `subprocess` argv (not the shell pipe), or avoid them.
- **Don't `keeper shell < file` for `tree`** — it can hang on large output. Pipe via stdin
  (`printf '...' | keeper shell` or `subprocess.run(input=...)`).
- **`upload-attachment` takes the record UID/PATH positional, NOT the title.** Passing a
  title silently no-ops — the file record is created but EMPTY (this cost a whole re-run). And
  the attachment lives in the record's `fileRef` field VALUE, not a top-level `files` key —
  verify there (or `download-attachment <UID> --out-dir`). Pattern: record-add all → let them
  sync → `upload-attachment <UID> --file <path>` in a second paced pass.
- **em-dash (—) in record titles breaks `kp pass <title>` retrieval.** Use plain hyphens `-`.

## Reusable batch pattern

Build every batch from the current vault. Put the exact `mkdir`, `mv`, `record-update`, `rndir`,
or `upload-attachment` commands into one temporary Commander command file, end it with `quit`,
then run one `keeper shell < batch.kc` session. Keep batches small, save completed identifiers in
a local progress file, stop on a master-password prompt, and verify each write from fresh Keeper
output. For file records, create records first, let them sync, then attach by record UID in a
second paced pass.

Router key `sk-9s9ef6` — resolved by the skills index on load.
