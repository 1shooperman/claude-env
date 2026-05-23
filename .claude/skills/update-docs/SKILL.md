---
name: update-docs
description: Update the local docs accordingly.
allowed-tools: [Read, Write, Edit, Bash(git log *), Bash(git -C *), Bash(git diff *), Bash(git add *), Bash(git commit *), Bash(git push *)]
user-invocable: false
---

## Instruction

Keep all documentation in sync after changes. Three targets:

1. **Root README** — `README.md` at repo root; reflects the full usage and install / upgrade instructions
2. **GitHub wiki** — markdown pages in `wiki/claude-env.wiki/`; committed and pushed to the wiki remote after changes
3. **Root CLAUDE.md** - baseline Claude instructions. Keep up to date with relevant bits from the current session. Prefer efficient token usage over verbosity for CLAUDE.md files.

## Rules

- Only list `user-invocable: true` skills in READMEs — do not expose internal dependency skills
- Do not conflate internal references with user-invocable commands

## Arguments

The user invoked this with: $ARGUMENTS

## Instructions

When this skill is invoked:

1. Read `git log --oneline -10` and `git diff HEAD~1..HEAD --name-only` to understand what changed
2. Update root `README.md` if the instruction list changed
3. Update the wiki:
   - Edit `wiki/claude-env.wiki/Home.md` with a current overview of available commands and skills
   - Create or update additional wiki pages (e.g. `Hook-Permissions.md`, `Cache-Architecture.md`) if the change warrants it
   - Commit and push the wiki changes:
     ```bash
     git -C wiki/claude-env.wiki add -A
     git -C wiki/claude-env.wiki commit -m "docs: sync wiki after <brief summary>"
     git -C wiki/claude-env.wiki push
     ```
4. Report what was updated across all three targets
