# Keeper folder colours — the scheme + how to apply it⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠

> Keeper has exactly **6 folder colours** (+ none): `red green blue orange yellow gray`.
> So "every folder its own colour" is impossible — the goal is "spot the right area instantly".
> The scheme below does that: **entity = colour, subfolder = colour-by-type**.

## How to set a folder colour (CLI — the only reliable way)
```
keeper rndir -q --color <colour> "<full folder path>"
```
- `--color` choices: `none red green blue orange yellow gray`.
- `-q` = quiet (suppresses the folder-info dump that otherwise blocks a batch).
- No `--name` needed — colour-only is fine.
- The app's folder right-click menu does NOT have colour. It's hidden in the folder detail
  panel's ⋮ menu → "Change Color" (manual, one at a time). Use the CLI for any volume.

## The scheme
**Top-level folders** — each a distinct colour (cycle the 6). Keep any the owner already chose.

**Entity folders** (under Companies) — each entity its own colour, e.g.:
| Entity | Colour |
|---|---|
| Operating company | green |
| Trust / holding | blue |
| Wound-down / cancelled entity | orange or yellow |
| Sole trader / studio | gray |

**Subfolders — coloured by CATEGORY, identically across every entity** (so colour = type):
| Subfolder | Colour |
|---|---|
| Identifiers | blue |
| Banking / Banking & Cards | green |
| Tax & BAS | orange |
| Insurance & Licences | yellow |
| People | red |
| Documents / Registration | gray |
| IDs & Government | blue |
| Health | red |
| Qualifications | orange |

Result: glance at the sidebar → green = an entity or its banking, blue = identifiers, etc.

## Applying at scale (PACED — see RATE-LIMITS.md)
Build the `rndir` lines from the current vault tree, then run **about 10 per `keeper shell`
session with a 10-15s pause between sessions**, tracking completed paths so you can resume. A
single 60-90 command colour blast will trip the rate-limiter mid-way.

```python
# pseudo: paths from `tree` (parse indentation), colour by rule, chunk + pace
for chunk in chunks(paths, 10):
    session([f'rndir -q --color {colour(p)} "{p}"' for p in chunk])   # ONE keeper shell
    if rate_limited: save_progress(); break                           # resume next run
    sleep(12)
```

## Verify
Screenshot the Keeper desktop app. You should see distinct entity colours and consistent
subfolder colours. Colours are NOT visible in `tree`/`ls` output — only in the app UI.

Router key `sk-9s9ef6` — resolved by the skills index on load.
