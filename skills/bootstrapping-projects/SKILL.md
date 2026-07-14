---
name: bootstrapping-projects
description: Use when starting a brand-new project or repository from scratch — triggers like "bootstrap a project", "start a new project", "new repo", "init a repo and put it on GitHub", "spin up a new private repo", "create me a new project". For going from nothing to a named, private GitHub repo with onboarding files.
---

# Bootstrapping a New Project

## Overview

Take a project from nothing to a **named, private GitHub repo** with onboarding in place: local git repo → creative name → scaffold (README, CLAUDE.md, .gitignore, LICENSE) → first commit → confirm → private remote + push → persistent memory entry.

**Core principle:** Gather context once, scaffold deterministically, and treat publishing to GitHub as the one irreversible step that needs explicit confirmation.

## When to Use

- "Bootstrap / start / spin up a new project (or repo)"
- "Init a repo and put it on GitHub (private)"
- Any greenfield start where there's no repo yet

**When NOT to use:** an existing repo that just needs a remote (use `gh repo create --source=.` directly), or adding files to a project that already exists.

## Guardrails — read before any command

These are the traps that bite. Honor every one.

- **Never `git init` inside an existing repo.** The session cwd may already be a git repo (a `~/projects` parent often is). Run `git rev-parse --show-toplevel` at the intended parent; if it returns a path, the new project would be **nested**. Stop and pick a location *outside* any repo.
- **Confirm the name is free** — both the local directory AND the GitHub repo — before committing to it. `gh repo create` fails late otherwise.
- **`.env` must be in `.gitignore` before the first `git add`.** Eyeball `git status` before committing so no secret is staged.
- **Always `--private`.** Never `--public`. Never assume; the request is private.
- **Publishing is the confirmation gate.** Creating the GitHub repo + pushing makes code leave the machine. Show the plan and get an explicit OK first (this is the only required confirmation).

## Workflow

### 1. Preflight (read-only)

```bash
gh auth status                 # logged in? needs 'repo' scope
gh api user --jq .login        # which account (e.g. oxedom)
git rev-parse --show-toplevel  # run at intended PARENT — must NOT already be a repo
```

If the intended parent is inside a repo, choose a location outside it before continuing.

### 2. Gather context (one batched round)

**Ask only for fields the user hasn't already answered.** If their request already gave the purpose, stack, or theme, don't re-ask it — go straight to the remaining unknowns. Batch the unknowns into one **AskUserQuestion** call:
- **What is it?** one-line purpose (drives name + docs)
- **Tech stack / language?** (Python, Node/TS, Go, Rust, docs-only…) — drives `.gitignore` + scaffold
- **Naming theme/vibe?** the metaphor or feel to generate names around (this skill uses *theme-then-generate*)
- **Parent directory + LICENSE** (default LICENSE: MIT)

If the theme is already given, skip the theme question here and proceed directly to name generation in §3.

### 3. Generate the name (theme → pick)

From the theme, generate **5 candidate names** + a one-word rationale each. Present them with **AskUserQuestion** and let the user pick or override. Derive the GitHub slug as kebab-case of the chosen name; check availability:

```bash
test -e <parent>/<slug> && echo "DIR EXISTS"   # local collision
gh repo view <account>/<slug> 2>/dev/null && echo "REPO EXISTS"   # remote collision (404 = free)
```

### 4. Init the repo

```bash
mkdir -p <parent>/<slug>
git -C <parent>/<slug> init -b main
```

Use `git -C <path>` (not `cd`) — the shell cwd resets between calls and `cd` can trigger a prompt. `-b main` matches GitHub's default branch.

### 5. Scaffold onboarding (all four artifacts)

Hand-author `README.md` and `CLAUDE.md` with the **Write tool** (not `echo`/heredoc). The two fetched files (`.gitignore`, `LICENSE`) come from `gh api` — a redirect is fine for those. Create all four:

- **`.gitignore`** — fetch a stack template, then ALWAYS append `.env` and OS/editor noise:
  ```bash
  gh api /gitignore/templates/Python --jq .source > <dir>/.gitignore   # or Node, Go, Rust…
  printf '\n.env\n.env.*\n.DS_Store\n.idea/\n.vscode/\n' >> <dir>/.gitignore
  ```
- **`LICENSE`** — fetch chosen license body, substitute the year and the user's name:
  ```bash
  YEAR=$(date +%Y); NAME=$(gh api user --jq '.name // .login')   # full name, else login
  gh api /licenses/mit --jq .body | sed "s/\[year\]/$YEAR/; s/\[fullname\]/$NAME/" > <dir>/LICENSE
  ```
- **`README.md`** — see template below.
- **`CLAUDE.md`** — see template below; so future Claude sessions know the repo instantly.

Scaffold **only these four onboarding files** — no `pyproject.toml`, `src/`, or framework skeleton unless the user asks. The job is "nothing → named private repo with onboarding," not a full code scaffold.

### 6. First commit ("save")

```bash
git -C <dir> add -A
git -C <dir> status          # verify NO .env / secrets staged
git -C <dir> commit -m "chore: bootstrap <name> project scaffold"
```

End the commit message with the user's trailer:
`Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`

### 7. Confirm before push (required gate)

Show: account, repo slug, **PRIVATE**, commit count. Get an explicit OK (AskUserQuestion or a direct yes/no). Do not skip.

### 8. Create private remote + push

```bash
gh repo create <slug> --private --source=<dir> --remote=origin \
  --description "<one-liner>" --push
gh repo view <slug> --json visibility,url   # verify visibility == PRIVATE
```

`--push` already sets up `origin` and upstream tracking — no separate `git push` needed. **On failure:** name taken → pick another slug and retry; a secret got staged → `git rm --cached <file>`, add it to `.gitignore`, `git commit --amend`, then push.

### 9. Persistent memory entry (the easily-forgotten step)

Onboard *future sessions*, not just this repo. Write a memory file into the session's auto-memory directory — the one whose `MEMORY.md` is loaded into context at session start. It's `~/.claude/projects/<cwd-with-slashes-as-dashes>/memory/` (e.g. a session started from `~/projects` maps to `~/.claude/projects/-home-<user>-projects/memory/`):

`project_<slug>.md`:
```markdown
---
name: project-<slug>
description: <one-line purpose> — <stack>, private repo <account>/<slug>
metadata:
  type: project
---

<2-3 sentences: what it is, stack, repo URL, current status.>
```
Then add one index line to `MEMORY.md`:
`- [<Name>](project_<slug>.md) — <hook>`

### 10. Report

Give the user: repo URL, confirmed PRIVATE, files created, local path, and the memory entry written.

## README.md template

```markdown
# <Name>

<one-line description>

## What this is
<2-3 sentences of motivation / what it does.>

## Setup
\`\`\`bash
git clone <repo-url> && cd <slug>
# install deps (stack-specific)
\`\`\`

## Usage
<how to run / dev loop>

> Status: early WIP.
```

## CLAUDE.md template

```markdown
# <Name>

<one-line purpose>

- **Stack:** <language / framework>
- **Run:** <command>
- **Test:** <command>
- **Layout:** <key dirs once they exist>

## Conventions
<anything a future session must know.>
```

## Quick Reference

| Step | Command |
|------|---------|
| Auth + account | `gh auth status` / `gh api user --jq .login` |
| Repo-nesting check | `git rev-parse --show-toplevel` (at parent) |
| Remote name free? | `gh repo view <account>/<slug>` (404 = free) |
| Init | `git -C <dir> init -b main` |
| gitignore template | `gh api /gitignore/templates/<Lang> --jq .source` |
| license text | `gh api /licenses/<key> --jq .body` |
| Create private + push | `gh repo create <slug> --private --source=<dir> --remote=origin --push` |
| Verify private | `gh repo view <slug> --json visibility,url` |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| `git init` in the cwd that's already a repo → nested repo | Check `rev-parse --show-toplevel` first; create outside it |
| Forgetting the auto-memory entry (step 9) | It's the whole point of "onboarding for me" — don't stop at repo creation |
| `.env` committed in first commit | Gitignore it before `add`; check `git status` |
| Pushing before confirming | Publishing is irreversible-ish; gate on explicit OK |
| Name slug ≠ checked for collisions | Check local dir + `gh repo view` before init |
| Creating `--public` by reflex | Always `--private` |
| Over-scaffolding a heavy framework | Keep scaffold minimal, matched to stated stack |
