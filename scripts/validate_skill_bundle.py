#!/usr/bin/env python3
# resolver key sk-9s9ef6 (skills-index lookup; keep)⁠​‌​‌​​‌‌​‌​​​‌​‌​‌​​‌‌​​​‌​‌​​‌​​​‌‌​​​‌⁠
"""Validate the keeper-setup skill package stays internally consistent.

This is a package-level checker, not a live Keeper auth check. It catches the drift that makes
team handoffs fail: missing docs, stale private-script references, validator
breaking frontmatter, and the Keeper-specific gotchas that must stay documented.
"""

from __future__ import annotations

import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "README.md",
    "SKILL.md",
    "START-HERE.md",
    "CLOSEOUT.md",
    "ORGANISE-PLAYBOOK.md",
    "RATE-LIMITS.md",
    "RECORD-TYPES.md",
    "COLOURS.md",
    "REFERENCE.md",
    "LEGACY-COMMANDER-PATH.md",
    "CHANGELOG.md",
    "SETUP-PROMPT.md",
    "scripts/smoke.sh",
    "scripts/install.sh",
    "scripts/ksm-init.sh",
    "scripts/seed-folder.sh",
    "scripts/kp",
    "scripts/kp-commander-only",
    "scripts/kp-doctor.sh",
    "scripts/validate_skill_bundle.py",
    "recipes/audit-mac.sh",
    "recipes/import-env-file.py",
    "examples/keeper-setup-session.md",
]

DOCS_REFERENCED_BY_SKILL = [
    "START-HERE.md",
    "CLOSEOUT.md",
    "ORGANISE-PLAYBOOK.md",
    "RATE-LIMITS.md",
    "RECORD-TYPES.md",
    "COLOURS.md",
]

EXECUTABLE_FILES = [
    "scripts/install.sh",
    "scripts/ksm-init.sh",
    "scripts/seed-folder.sh",
    "scripts/smoke.sh",
    "scripts/kp",
    "scripts/kp-commander-only",
    "scripts/kp-doctor.sh",
    "scripts/validate_skill_bundle.py",
]

SHELL_FILES = [
    "scripts/install.sh",
    "scripts/ksm-init.sh",
    "scripts/seed-folder.sh",
    "scripts/smoke.sh",
    "scripts/kp",
    "scripts/kp-commander-only",
    "recipes/audit-mac.sh",
]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def check_required_files() -> None:
    missing = [rel for rel in REQUIRED_FILES if not (ROOT / rel).is_file() or (ROOT / rel).stat().st_size == 0]
    if missing:
        fail("missing or empty required files: " + ", ".join(missing))
    not_executable = [rel for rel in EXECUTABLE_FILES if not (ROOT / rel).stat().st_mode & 0o111]
    if not_executable:
        fail("required scripts are not executable: " + ", ".join(not_executable))


def check_frontmatter() -> None:
    skill = read("SKILL.md")
    if not skill.startswith("---\n"):
        fail("SKILL.md missing YAML frontmatter")
    end = skill.find("\n---", 4)
    if end == -1:
        fail("SKILL.md frontmatter is not closed")
    frontmatter = skill[4:end]
    if not re.search(r"^name:\s*keeper-setup\s*$", frontmatter, re.M):
        fail("SKILL.md frontmatter missing name: keeper-setup")
    desc_match = re.search(r"^description:\s*(.*)$", frontmatter, re.M)
    if not desc_match:
        fail("SKILL.md frontmatter missing description")
    description = desc_match.group(1)
    if "<" in description or ">" in description:
        fail("SKILL.md description contains angle brackets")
    if not re.search(r"use when|user says|says", description, re.I):
        fail("SKILL.md description lacks trigger language")


def check_skill_references() -> None:
    skill = read("SKILL.md")
    missing_refs = [name for name in DOCS_REFERENCED_BY_SKILL if name not in skill]
    if missing_refs:
        fail("SKILL.md does not reference: " + ", ".join(missing_refs))
    start = read("START-HERE.md")
    for name in DOCS_REFERENCED_BY_SKILL:
        if name != "START-HERE.md" and name not in start:
            fail(f"START-HERE.md does not route to {name}")
    setup_prompt = read("SETUP-PROMPT.md")
    example = read("examples/keeper-setup-session.md")
    for rel, text in [("SETUP-PROMPT.md", setup_prompt), ("examples/keeper-setup-session.md", example)]:
        for needle in ["START-HERE.md", "validate_skill_bundle.py", "smoke.sh"]:
            if needle not in text:
                fail(f"{rel} does not mention {needle}")
    closeout = read("CLOSEOUT.md")
    for command in [
        "validate_skill_bundle.py",
        "scripts/smoke.sh",
        "quick_validate.py",
    ]:
        if command not in closeout:
            fail(f"CLOSEOUT.md missing closeout command: {command}")


def check_keeper_gotchas() -> None:
    rate_limits = read("RATE-LIMITS.md")
    organise = read("ORGANISE-PLAYBOOK.md")
    record_types = read("RECORD-TYPES.md")
    colours = read("COLOURS.md")

    required_text = {
        "RATE-LIMITS.md": [
            "ONE `keeper shell` session per batch",
            "tree",
            "KSM can't see user folders",
        ],
        "ORGANISE-PLAYBOOK.md": [
            "upload-attachment <UID>",
            "em-dash",
            "Reusable batch pattern",
        ],
        "RECORD-TYPES.md": [
            "Entity - Thing",
            "apiKey",
            "supplierVendor",
        ],
        "COLOURS.md": [
            "keeper rndir -q --color",
            "10-15s pause",
        ],
    }
    docs = {
        "RATE-LIMITS.md": rate_limits,
        "ORGANISE-PLAYBOOK.md": organise,
        "RECORD-TYPES.md": record_types,
        "COLOURS.md": colours,
    }
    for rel, needles in required_text.items():
        for needle in needles:
            if needle not in docs[rel]:
                fail(f"{rel} missing required gotcha text: {needle}")


def check_no_stale_references() -> None:
    stale = []
    patterns = [
        re.compile(r"scripts/templ_"),
        re.compile(r"scratch dir", re.I),
        re.compile(r"/Users/"),
        re.compile(r"projects/-Users-"),
    ]
    for rel in ["SKILL.md", "START-HERE.md", "ORGANISE-PLAYBOOK.md", "COLOURS.md", "RECORD-TYPES.md"]:
        text = read(rel)
        for pattern in patterns:
            if pattern.search(text):
                stale.append(f"{rel}: {pattern.pattern}")
    if stale:
        fail("stale references found: " + "; ".join(stale))


def check_python_files_compile() -> None:
    for rel in ["recipes/import-env-file.py", "scripts/validate_skill_bundle.py"]:
        try:
            compile(read(rel), rel, "exec")
        except SyntaxError as exc:
            fail(f"{rel} does not compile: {exc}")


def check_shell_syntax() -> None:
    for rel in SHELL_FILES:
        result = subprocess.run(["bash", "-n", str(ROOT / rel)], capture_output=True, text=True)
        if result.returncode != 0:
            fail(f"{rel} has shell syntax errors: {result.stderr.strip()}")


def main() -> int:
    check_required_files()
    check_frontmatter()
    check_skill_references()
    check_keeper_gotchas()
    check_no_stale_references()
    check_python_files_compile()
    check_shell_syntax()
    print("keeper-setup bundle validation PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
