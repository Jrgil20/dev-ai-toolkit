---
name: agy
description: "Trigger: delegate to Antigravity, agy, ask Gemini/Antigravity to do X, continue an agy conversation. Hands self-contained, low-risk tasks to the Antigravity CLI in API-key mode and reviews the result with git diff."
metadata:
  added: "2026-11-17"
  updated: "2026-11-17"
  review-by: "2027-05-17"
  volatility: "tooling"
  status: "active"
  lang: "en"
  origin: "own"
---

# Antigravity via `agy`

Delegate a task to the Antigravity CLI (`agy`, on `PATH`) and review what it wrote. Antigravity is a draft generator: Claude stays responsible for the result.

## Authentication

Orchestrating `agy` from Claude Code with a personal Google login may breach the Antigravity terms. The intended mode is API-key mode:

- `~/.gemini/antigravity-cli/settings.json` has `"modelProvider": "gemini"`, and
- `GEMINI_API_KEY` is exported by the user (never print, store, or pass it in a prompt).

Always call agy through `scripts/agy-run.sh`. Without API-key mode it exits with code 64, unless the user exported `AGY_ALLOW_OAUTH=1` in their shell profile to accept the risk; then it runs with the personal login and prints a warning.

- On exit 64, stop and tell the user. Never set `AGY_ALLOW_OAUTH` yourself: that decision belongs to the user.
- When the warning appears, mention once in the report that delegation used the personal login.

API-key mode is billed per use in AI Studio; the personal login consumes the user's subscription quota. Either way, delegate only when it saves real Claude work: mechanical, well-scoped tasks.

## Model selection

Default: `gemini-3.8-flash-medium`. Run `agy models` after any auth change and use only listed IDs; non-Gemini models may not be available in API-key mode.

| Task | Model | Effort |
| --- | --- | --- |
| Mechanical: rename, format, boilerplate, summaries, lookups | `gemini-3.8-flash-medium` | `medium` |
| Same, but the user asked for care | `gemini-3.8-flash-high` | `high` |
| Non-trivial code changes | Do it in Claude, unless the user explicitly asks to delegate | — |

If the user names a model or effort, use theirs.

## Running a task

```bash
scripts/agy-run.sh -p "<prompt>" --model <id> --effort <level> --mode <plan|accept-edits> --output-format text
```

- Model IDs carry their effort: `--effort` must match the suffix (`gemini-3.8-flash-medium` with `--effort medium`), or agy exits 1 with "conflicts with --effort".
- Headless mode cannot ask for permissions: a tool without an allow rule is auto-denied and agy still exits 0. The wrapper turns that into exit 65. Allow rules use `command(<cmd>)`, `write_file(<dir>/)`, and `mcp(<server>/<tool>)` or `mcp(<server>/*)` (bare `mcp(<server>)` does not match). Rules live in the user's agy settings: propose the exact rule and let the user add it.
- The wrapper adds a hard `timeout` (`AGY_HARD_TIMEOUT`, default 900 s) and a `--print-timeout` 30 s shorter, unless you pass one. `agy -p` can hang without a TTY (antigravity-cli issue #318); exit 124 means it timed out. Report it; do not retry silently.
- Run from the target directory and add it with `--add-dir <path>` (repeatable). `--dir` is not a session flag.
- For long tasks, launch the wrapper with Bash `run_in_background`; the hard timeout still applies.
- Multi-step work: continue with `-c` (latest conversation) or `--conversation <id>`; do not resend context.

## Prompt contract (keeps context cheap)

Antigravity does not see this conversation. Every prompt states:

1. Goal and acceptance criteria.
2. **Paths** to read and to edit. Never paste file contents.
3. What not to touch.
4. Output: "Write your changes to disk. Reply only with a digest of at most 10 lines: files changed, what changed, commands run and their result, open issues."

## Isolation and permissions

- One task at a time may run in the main checkout. Parallel tasks each get a worktree: `git worktree add ../<repo>-agy-<slug> -b agy/<slug>`, then run from that path.
- `--dangerously-skip-permissions` only inside a disposable worktree, never in the main checkout, and only after the user approved the task. Combine it with `--sandbox`.
- Prefer `--mode plan` first for code changes; run `--mode accept-edits` once the plan is approved.

## Review (proportional)

1. `git diff --stat`, then `git diff` only on changed files. Look for scope creep, deleted code, invented APIs, hardcoded values, secrets.
2. Run the project's existing tests/lint/build once, output trimmed to failures. Report the real result.
3. Small problems: fix them yourself. Large ones: one follow-up with `-c` listing the exact issues. At most one retry, then do it yourself and say why.
4. Report what agy did, what you verified, what you changed, and what is unverified.

## Notes

- Confirm with the user before delegating tasks that modify files or run commands, unless already authorized.
- Never put credentials or secrets in a prompt.
- On failure, report the exact error output; do not change flags and retry silently.
- Discovery: `agy --help`, `agy models`, `agy agents`, `agy mcp list`.
