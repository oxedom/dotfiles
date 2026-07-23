#!/usr/bin/env python3
"""Find Claude Code / Codex CLI sessions that were alive when the machine died.

Reads the on-disk journals both CLIs write per turn and reports, for each
session active since a cutoff, whether it finished its turn or was cut off
mid-tool. Read-only; touches nothing but stdout.

Usage:
    ./classify-sessions.py                    # since last boot
    ./classify-sessions.py --since "2024-01-30 09:00"
    ./classify-sessions.py --since 2024-01-30 --json
"""

import argparse
import datetime as dt
import glob
import json
import os
import re
import sys

CLAUDE_GLOB = "~/.claude/projects/*/*.jsonl"
CODEX_GLOB = "~/.codex/sessions/*/*/*/rollout-*.jsonl"


def boot_time():
    """Local boot time from /proc/stat btime (Linux)."""
    try:
        with open("/proc/stat") as fh:
            for line in fh:
                if line.startswith("btime"):
                    return dt.datetime.fromtimestamp(int(line.split()[1]))
    except OSError:
        pass
    return None


def parse_since(text):
    if not text:
        return boot_time()
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M", "%Y-%m-%d"):
        try:
            return dt.datetime.strptime(text, fmt)
        except ValueError:
            continue
    sys.exit(f"unparseable --since: {text!r}")


def read_jsonl(path):
    rows = []
    try:
        with open(path, errors="replace") as fh:
            for line in fh:
                line = line.strip()
                if line:
                    try:
                        rows.append(json.loads(line))
                    except json.JSONDecodeError:
                        pass  # truncated tail is expected after a hard crash
    except OSError:
        pass
    return rows


def to_local(iso):
    """Journals timestamp in UTC; the operator thinks in local time."""
    if not iso:
        return None
    try:
        stamp = dt.datetime.fromisoformat(iso.replace("Z", "+00:00"))
    except ValueError:
        return None
    return stamp.astimezone().replace(tzinfo=None)


def last_timestamp(rows):
    for row in reversed(rows):
        stamp = to_local(row.get("timestamp"))
        if stamp:
            return stamp
    return None


def classify_claude(path):
    rows = read_jsonl(path)
    if not rows:
        return None

    started, finished = {}, set()
    cwd = branch = None
    for row in rows:
        cwd = row.get("cwd") or cwd
        branch = row.get("gitBranch") or branch
        content = row.get("message", {}).get("content")
        if not isinstance(content, list):
            continue
        for block in content:
            if not isinstance(block, dict):
                continue
            if block.get("type") == "tool_use":
                started[block.get("id")] = block.get("name")
            elif block.get("type") == "tool_result":
                finished.add(block.get("tool_use_id"))

    # A tool call with no result is a turn that never came back.
    pending = [name for tid, name in started.items() if tid not in finished]
    return {
        "agent": "claude",
        "id": os.path.basename(path)[:-len(".jsonl")],
        "cwd": cwd,
        "branch": branch,
        "last": last_timestamp(rows),
        "mid_task": bool(pending),
        "pending": pending,
        "resume": f"claude --resume {os.path.basename(path)[:-len('.jsonl')]}",
    }


def classify_codex(path):
    rows = read_jsonl(path)
    if not rows:
        return None

    meta = rows[0].get("payload", {}) if rows[0].get("type") == "session_meta" else {}
    session_id = meta.get("session_id") or ""
    if not session_id:
        match = re.search(r"rollout-.*?-([0-9a-f-]{36})\.jsonl$", path)
        session_id = match.group(1) if match else os.path.basename(path)

    # Codex emits task_complete when a turn lands. Absence == interrupted.
    completed = False
    for row in reversed(rows):
        payload = row.get("payload", {})
        if isinstance(payload, dict) and payload.get("type") == "task_complete":
            completed = True
            break
        if isinstance(payload, dict) and payload.get("type") in {
            "agent_message", "function_call", "exec_command_begin"
        }:
            break

    return {
        "agent": "codex",
        "id": session_id,
        "cwd": meta.get("cwd"),
        "branch": None,
        "last": last_timestamp(rows),
        "mid_task": not completed,
        "pending": [],
        "resume": f"codex resume {session_id}",
    }


def collect(since):
    out = []
    for pattern, fn in ((CLAUDE_GLOB, classify_claude), (CODEX_GLOB, classify_codex)):
        for path in glob.glob(os.path.expanduser(pattern)):
            if dt.datetime.fromtimestamp(os.path.getmtime(path)) < since:
                continue  # cheap prefilter before parsing
            row = fn(path)
            if row and row["last"] and row["last"] >= since:
                out.append(row)
    out.sort(key=lambda r: r["last"], reverse=True)
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--since", help="cutoff, local time (default: last boot)")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    args = ap.parse_args()

    since = parse_since(args.since)
    if since is None:
        sys.exit("could not determine boot time; pass --since")

    rows = collect(since)

    if args.json:
        print(json.dumps(
            [{**r, "last": r["last"].isoformat()} for r in rows], indent=2))
        return

    print(f"sessions active since {since:%Y-%m-%d %H:%M} (local)\n")
    if not rows:
        print("  none found")
        return

    for row in rows:
        state = "MID-TASK" if row["mid_task"] else "idle"
        gone = row["cwd"] and not os.path.isdir(os.path.expanduser(row["cwd"]))
        print(f"[{state:8}] {row['agent']:6} {row['last']:%H:%M}  {row['id']}")
        print(f"           cwd: {row['cwd']}{'  <-- MISSING' if gone else ''}")
        if row["branch"]:
            print(f"           branch: {row['branch']}")
        if row["pending"]:
            print(f"           unfinished tool calls: {', '.join(row['pending'])}")
        print(f"           {row['resume']}")
        print()


if __name__ == "__main__":
    main()
