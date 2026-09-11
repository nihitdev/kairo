#!/usr/bin/env python3
"""Dependency-free repository format, link, and vendoring checks."""

from __future__ import annotations

import json
import re
import sys
import tomllib
import xml.etree.ElementTree as element_tree
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ERRORS: list[str] = []
IGNORED_PARTS = {".git", "node_modules", "dist"}


def is_repository_file(path: Path) -> bool:
    return not IGNORED_PARTS.intersection(path.relative_to(ROOT).parts)


def error(path: Path, message: str) -> None:
    ERRORS.append(f"{path.relative_to(ROOT)}: {message}")


def strip_json_comments(text: str) -> str:
    output: list[str] = []
    index = 0
    in_string = False
    escaped = False
    while index < len(text):
        char = text[index]
        following = text[index + 1] if index + 1 < len(text) else ""
        if in_string:
            output.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            index += 1
            continue
        if char == '"':
            in_string = True
            output.append(char)
            index += 1
        elif char == "/" and following == "/":
            index += 2
            while index < len(text) and text[index] not in "\r\n":
                index += 1
        elif char == "/" and following == "*":
            end = text.find("*/", index + 2)
            if end < 0:
                raise ValueError("unterminated block comment")
            index = end + 2
        else:
            output.append(char)
            index += 1
    return "".join(output)


def validate_structured_files() -> None:
    for path in ROOT.rglob("*.json"):
        if is_repository_file(path):
            try:
                json.loads(path.read_text(encoding="utf-8"))
            except Exception as exc:  # noqa: BLE001 - report parser details
                error(path, f"invalid JSON: {exc}")

    for path in ROOT.rglob("*.jsonc"):
        if not is_repository_file(path):
            continue
        try:
            json.loads(strip_json_comments(path.read_text(encoding="utf-8")))
        except Exception as exc:  # noqa: BLE001
            error(path, f"invalid JSONC: {exc}")

    for path in ROOT.rglob("*.toml"):
        if not is_repository_file(path):
            continue
        try:
            tomllib.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:  # noqa: BLE001
            error(path, f"invalid TOML: {exc}")

    for pattern in ("*.xml", "*.xaml"):
        for path in ROOT.rglob(pattern):
            if not is_repository_file(path):
                continue
            try:
                element_tree.parse(path)
            except Exception as exc:  # noqa: BLE001
                error(path, f"invalid XML: {exc}")

    for path in ROOT.rglob("*.hjson"):
        if not is_repository_file(path):
            continue
        text = path.read_text(encoding="utf-8")
        if text.count("{") != text.count("}") or text.count("[") != text.count("]"):
            error(path, "unbalanced HJSON delimiters")


def validate_markdown_links() -> None:
    link_pattern = re.compile(r"!?\[[^\]]*\]\(([^)\s]+)")
    for path in ROOT.rglob("*.md"):
        if not is_repository_file(path):
            continue
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            for match in link_pattern.finditer(line):
                target = match.group(1).strip("<>")
                if target.startswith(("http://", "https://", "mailto:", "#")):
                    continue
                local_target = target.split("#", 1)[0]
                if local_target and not (path.parent / local_target).resolve().exists():
                    error(path, f"line {line_number}: missing local link target {target!r}")


def strip_css_comments(text: str) -> str:
    return re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)


def validate_css() -> None:
    mutable_github = re.compile(
        r"(?:raw\.githubusercontent\.com/[^/]+/[^/]+/(?:main|master|refs/heads/)|github\.io/)"
    )
    for path in ROOT.rglob("*.css"):
        if not is_repository_file(path):
            continue
        text = path.read_text(encoding="utf-8")
        bare = strip_css_comments(text)
        if bare.count("{") != bare.count("}"):
            error(path, "unbalanced CSS braces")
        if mutable_github.search(text):
            error(path, "mutable GitHub-hosted CSS or asset URL")


def validate_vendored_files() -> None:
    licenses = list((ROOT / ".config/yazi/plugins").glob("*.yazi/LICENSE"))
    for path in licenses:
        text = path.read_text(encoding="utf-8")
        if "MIT License" not in text or len(text.splitlines()) < 20:
            error(path, "missing complete vendored license")

    wezterm_license = ROOT / ".config/wezterm/LICENSE"
    if not wezterm_license.is_file():
        error(wezterm_license, "missing vendored MIT license")
    else:
        text = wezterm_license.read_text(encoding="utf-8")
        if "Copyright (c) 2023 Kevin Silvester" not in text or len(text.splitlines()) < 20:
            error(wezterm_license, "missing complete vendored license or attribution")

    duplicate_a = ROOT / ".config/bat/themes/Catppuccin Mocha.tmTheme"
    duplicate_b = ROOT / ".config/yazi/flavors/catppuccin-mocha.yazi/tmtheme.xml"
    if duplicate_a.read_bytes() != duplicate_b.read_bytes():
        error(duplicate_b, "must remain identical to the Bat Catppuccin Mocha theme")


def validate_workflow_pins() -> None:
    workflow_dir = ROOT / ".github/workflows"
    action_pattern = re.compile(r"\buses:\s*[^\s@]+@([^\s#]+)")
    for path in (*workflow_dir.glob("*.yml"), *workflow_dir.glob("*.yaml")):
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            match = action_pattern.search(line)
            if match and not re.fullmatch(r"[0-9a-f]{40}", match.group(1)):
                error(path, f"line {line_number}: action is not pinned to a full commit SHA")


def main() -> int:
    validate_structured_files()
    validate_markdown_links()
    validate_css()
    validate_vendored_files()
    validate_workflow_pins()
    if ERRORS:
        print("Repository validation failed:", file=sys.stderr)
        for finding in ERRORS:
            print(f"- {finding}", file=sys.stderr)
        return 1
    print("Repository formats, links, CSS pins, and vendored assets are valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
