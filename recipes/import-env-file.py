#!/usr/bin/env python3
# resolver key sk-9s9ef6 (skills-index lookup; keep)⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠
"""import-env-file.py — Import a single .env file into Keeper as one record.

Usage:
  python3 import-env-file.py <path-to-env-file> <record-title> [folder] [primary-key]

Examples:
  python3 import-env-file.py ~/projects/myapp/.env "MyApp Production env"
  python3 import-env-file.py ~/.config/foo.env "Foo Service" "Example Pty Ltd/Mac/Other" FOO_API_KEY

What it does:
  1. Parses KEY=VALUE lines (ignores comments, blanks, quoted values handled)
  2. Stores all vars as JSON in the Keeper record's notes field
  3. Uses primary-key (or first var) as the password field
  4. Files stay on disk — Keeper is a backup, not a replacement

Master password must be unlocked (persistent_login on) for this to work.
"""
import json
import subprocess
import sys
from pathlib import Path


def parse_env(path):
    result = {}
    for line in Path(path).read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        k = k.strip()
        v = v.strip()
        if v and v[0] == v[-1] and v[0] in ('"', "'"):
            v = v[1:-1]
        result[k] = v
    return result


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    env_path = Path(sys.argv[1]).expanduser()
    title = sys.argv[2]
    folder = sys.argv[3] if len(sys.argv) > 3 else "Example Pty Ltd/Mac/Other"
    primary_key = sys.argv[4] if len(sys.argv) > 4 else None

    if not env_path.exists():
        print(f"FAIL: {env_path} not found")
        sys.exit(1)

    env_vars = parse_env(env_path)
    if not env_vars:
        print(f"FAIL: {env_path} has no parseable KEY=VALUE lines")
        sys.exit(1)

    primary = primary_key or sorted(env_vars.keys())[0]
    password = env_vars.get(primary, next(iter(env_vars.values())))

    notes_payload = {"_source": str(env_path), **env_vars}
    notes = json.dumps(notes_payload, indent=2)

    args = [
        "keeper", "record-add",
        "--record-type", "login",
        "--title", title,
        "--folder", folder,
        "--notes", notes,
        f"login={primary}",
        f"password={password}",
    ]
    print(f"Importing {env_path} -> '{title}' in folder '{folder}'...")
    r = subprocess.run(args, capture_output=True, text=True)
    if r.returncode != 0:
        print(f"FAIL: {(r.stderr or r.stdout).strip()}")
        sys.exit(1)
    uid = r.stdout.strip().split()[-1] if r.stdout.strip() else "?"
    print(f"OK: uid={uid}, {len(env_vars)} env vars stored")
    print(f"Verify: keeper get {uid}")
    print(f"On-disk file {env_path} is unchanged. Delete it manually only after confirming Keeper has the right data.")


if __name__ == "__main__":
    main()
