#!/usr/bin/env python3
"""Compile rules/*.md into AGENTS.md.

Mirrors the upstream vercel-labs/agent-skills build output format so this fork
can be refreshed against upstream without hand-editing the compiled document.

Usage: python3 build.py [--check]
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).parent
RULES = ROOT / "rules"

FM = re.compile(r"\A---\s*\n(.*?)\n---\s*\n", re.S)
# "**Incorrect (blocks both branches):**" -> "**Incorrect: blocks both branches**"
PARENS = re.compile(r"^\*\*([^*(\n]+?) \(([^)\n]+)\):\*\*$", re.M)


def frontmatter(text):
    m = FM.match(text)
    if not m:
        raise ValueError("missing frontmatter")
    meta = {}
    for line in m.group(1).splitlines():
        if ":" in line:
            k, _, v = line.partition(":")
            meta[k.strip()] = v.strip()
    return meta, text[m.end():]


def sections():
    text = (RULES / "_sections.md").read_text()
    out = []
    for m in re.finditer(
        r"^## \d+\.\s*(.+?)\s*\((\w+)\)\s*\n+\*\*Impact:\*\*\s*(.+?)\s*\n"
        r"\*\*Description:\*\*\s*(.+?)\s*$",
        text,
        re.M,
    ):
        title, prefix, impact, desc = m.groups()
        out.append({"title": title, "prefix": prefix, "impact": impact, "desc": desc})
    return out


def anchor(text):
    slug = re.sub(r"[^a-z0-9 -]", "", text.lower())
    return slug.replace(" ", "-")


def main():
    meta = json.loads((ROOT / "metadata.json").read_text())
    secs = sections()
    by_prefix = {s["prefix"]: [] for s in secs}

    for path in sorted(RULES.glob("*.md")):
        if path.name.startswith("_"):
            continue
        fm, body = frontmatter(path.read_text())
        prefix = path.stem.split("-")[0]
        if prefix not in by_prefix:
            raise SystemExit(f"{path.name}: unknown section prefix {prefix!r}")
        # drop the duplicated "## Title" heading; the compiler emits its own
        body = re.sub(r"\A\s*##\s+.+?\n", "", body).strip()
        body = PARENS.sub(r"**\1: \2**", body)
        by_prefix[prefix].append({**fm, "body": body, "file": path.name})

    for rules in by_prefix.values():
        rules.sort(key=lambda r: r["title"].lower())

    total = sum(len(r) for r in by_prefix.values())

    toc, chapters = [], []
    for si, sec in enumerate(secs, 1):
        toc.append(
            f"{si}. [{sec['title']}](#{si}-{anchor(sec['title'])}) — **{sec['impact']}**"
        )
        chapter = [f"## {si}. {sec['title']}", "", f"**Impact: {sec['impact']}**", "", sec["desc"], ""]
        for ri, rule in enumerate(by_prefix[sec["prefix"]], 1):
            num = f"{si}.{ri}"
            toc.append(f"   - {num} [{rule['title']}](#{anchor(num + ' ' + rule['title'])})")
            impact = rule.get("impact", "MEDIUM")
            if rule.get("impactDescription"):
                impact += f" ({rule['impactDescription']})"
            chapter += [f"### {num} {rule['title']}", "", f"**Impact: {impact}**", "", rule["body"], ""]
        chapters.append("\n".join(chapter).rstrip())

    refs = "\n".join(f"{i}. [{u}]({u})" for i, u in enumerate(meta["references"], 1))

    doc = "\n".join([
        "# React Best Practices",
        "",
        f"**Version {meta['version']}**",
        meta["date"],
        "",
        "> **Note:**",
        "> This document is mainly for agents and LLMs to follow when maintaining,",
        "> generating, or refactoring React codebases. Humans may also find it useful,",
        "> but guidance here is optimized for automation and consistency by AI-assisted workflows.",
        "",
        "---",
        "",
        "## Abstract",
        "",
        meta["abstract"],
        "",
        "---",
        "",
        "## Table of Contents",
        "",
        "\n".join(toc),
        "",
        "---",
        "",
        "\n\n---\n\n".join(chapters),
        "",
        "---",
        "",
        "## References",
        "",
        refs,
        "",
    ])

    out = ROOT / "AGENTS.md"
    if "--check" in sys.argv:
        if out.read_text() != doc:
            raise SystemExit("AGENTS.md is out of date; run: python3 build.py")
        print(f"AGENTS.md up to date ({total} rules)")
        return
    out.write_text(doc)
    print(f"wrote AGENTS.md: {total} rules across {len(secs)} sections")


if __name__ == "__main__":
    main()
