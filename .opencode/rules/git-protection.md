# Git Protection Rules

These rules protect the repository from unauthorized or destructive git actions.

## Non-negotiables

1. **Never initialize git** unless the user explicitly asks. This repository was
   not a git repo until the user requested it.
2. **Never commit, push, or create a pull request** without explicit user
   instruction. Staging and committing are user actions.
3. **Never force-push** (`--force`, `--force-with-lease`) without explicit
   confirmation. Force-pushing can destroy history.
4. **Never delete a branch** (local or remote) without explicit confirmation.
5. **Never rewrite history** (`rebase`, `filter-branch`, `filter-repo`,
   `commit --amend` on pushed commits) without explicit confirmation.
6. **Never modify git configuration** (user.name, user.email, remote URLs,
   hooks) without explicit user instruction.
7. **Never run destructive git commands** (`reset --hard`, `clean -fd`,
   `checkout -- .`) without explicit confirmation.
8. **Never bypass hooks** (`--no-verify`) unless the user explicitly requests it.

## Before any git write operation

- Confirm with the user what will happen.
- Show the diff or the list of files that will be affected.
- Never stage files that contain secrets, personal paths, or generated
  artifacts. Check `.gitignore` and run the publish audit first.

## Protected paths

These paths are gitignored and must never be committed:

- `AGENTS.md` (personal entry point)
- `agents/` (legacy, removed)
- `.opencode/` (personal tooling config)
- `.env` and `.env.*` (secrets)
- `_library/`, `manifest.json`, `*.log`, `artwork/` (generated artifacts)
- `GLM-test/`, `glm-*` (scratch data)

## Allowed without asking

- `git status`, `git diff`, `git log`, `git branch --list` (read-only).
- `git add` only when the user has asked to stage specific files.
- Creating a commit only when the user has asked to commit.

## Enforcement

If a requested action would violate these rules, explain why and ask for
explicit confirmation before proceeding. Do not silently comply.