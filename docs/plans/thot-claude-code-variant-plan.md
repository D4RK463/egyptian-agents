# thot-claude-code-variant — Work Plan

## TL;DR
What you get: a second, independently maintained Thot prompt that runs as the
main session in Claude Code (`claude --agent thot`), plus an example permission
snippet, an extended installer, and a README that documents the cross-tool
workflow and its weaker enforcement. / Why this approach: `claude --agent <name>`
replaces the system prompt and carries model, tool restrictions, and permission
mode, so it is the only Claude Code mechanism that matches opencode's
`mode: primary`. / What it does NOT do: no Imhotep variant, no changes to the
existing opencode agents, no generator, no writes into `~/.claude/settings.json`.
/ Effort: medium. / Risk: low — every change is additive and the existing
opencode installation is untouched.

## Execution rules

1. First load `skill(name="caveman")`; user output stays caveman-terse.
2. No commits or git history changes.
3. On start, read this whole plan, inspect current worktree, skip checked todos, and execute only the first unchecked implementation todo `N.`.
4. For that todo: implement, run listed QA, stop, call `question`, and wait.
5. After explicit `weiter` / `continue` / `ok` / `go`: persist later-needed facts/decisions in this plan, stage the todo's own files with `git add -- <Files>`, verify scope with `git diff --cached --name-only` (no baseline snapshot files needed), check off only that todo, remind the user to start a NEW session for token savings, print the next `/start-work` command for this plan, then stop.
6. When all implementation todos are checked at session start, run final verification tasks `F<n>` without gates. Stop only on failure; otherwise report once.
7. `Must-NOT-Have` is binding; extra ideas go to `## Findings`, not code.
8. If the plan is wrong or reality differs, stop and hand back to thot.
9. Never run `git stash` while staged plan work exists.

## Scope

**In:**
- New `claude/agents/thot.md`: Claude Code frontmatter plus the Thot prompt body
  with Claude Code tool names.
- New `claude/settings.example.json`: permission rules the user pastes into
  `~/.claude/settings.json`.
- `install.sh`: additional, optional symlink into `~/.claude/agents/`.
- `README.md`: prerequisites, installation, cross-tool workflow, honest
  enforcement table, two-file maintenance note, behavioural differences.

**Out:**
- Any behaviour change to the opencode agents or the opencode workflow.
- Automating `claude mcp add`.
- Automating edits to `~/.claude/settings.json`.

**Must-NOT-Have:**
- A Claude Code variant of Imhotep.
- Edits to `agent/thot.md` or `agent/imhotep.md`.
- A generator, a shared prompt body, or any `sed`-based prompt transformation.
- Translating the `## Execution rules` block into Claude Code vocabulary.
- Changing `command/start-work.md`.
- Writing into `~/.claude/settings.json` or `~/.claude.json` from `install.sh`.

## Findings

- `agent/thot.md:3` — `mode: primary`. Claude Code has no `mode` field. The
  equivalent is running the agent file as the main session via
  `claude --agent thot`; the agent's system prompt then replaces the Claude Code
  system prompt entirely, and its `model`, `tools`, and `permissionMode` apply.
  Source: https://docs.claude.com/en/docs/claude-code/sub-agents, section
  "Invoke subagents explicitly".
- `agent/thot.md:8-11` — `edit: "*": deny` with `docs/plans/**: allow`. Claude
  Code evaluates rules deny, then ask, then allow, and "a deny rule can't carry
  allowlist exceptions". A blanket `Edit` deny would also block `docs/plans/`.
  Source: https://docs.claude.com/en/docs/claude-code/permissions, section
  "Manage permissions". See D2.
- Claude Code permission rules written in **user** settings anchor `/path`
  against `~/.claude/path`, not against the project. The portable form for an
  allow rule is `Edit(docs/plans/**)`, which resolves against the current
  directory. Source: https://docs.claude.com/en/docs/claude-code/permissions,
  table "Rule defined in / `/path` resolves to". See D3.
- Claude Code auto-approves a built-in read-only Bash set in every mode: `ls`,
  `cat`, `echo`, `pwd`, `head`, `tail`, `grep`, `find`, `wc`, `which`, `diff`,
  `stat`, `du`, `cd`, and read-only `git` forms. Of `agent/thot.md:13-26` only
  `rg` and `fd` therefore still need explicit allow rules. `cat` is auto-approved
  even though opencode deliberately withholds it. Source:
  https://docs.claude.com/en/docs/claude-code/permissions, section "Read-only
  commands". See D9.
- `agent/thot.md:59` and `agent/thot.md:62` — `task(subagent_type="explore")` and
  `task(subagent_type="scout")`. Claude Code ships `Explore`, `Plan`,
  `general-purpose`, `claude`, and `statusline-setup`; there is no `scout`.
  Observed: `claude --agent thot -p "x"` printed
  `--agent 'thot' not found. Available agents: claude, Explore, general-purpose, Plan, statusline-setup`.
  See D8.
- `agent/thot.md:63-64` — `context7_resolve-library-id` and
  `context7_query-docs`. Claude Code names MCP tools `mcp__<server>__<tool>`.
  Source: https://docs.claude.com/en/docs/claude-code/permissions, section "MCP".
- `agent/thot.md` contains exactly two occurrences of the literal `` `question` ``
  (lines 83 and 147). Line 83 is Thot's own instruction and must become
  `AskUserQuestion`. Line 147 is inside the `## Execution rules` block that
  Imhotep executes in opencode and must stay unchanged. See D7.
- `install.sh:33` — `link()` aborts when the target exists and is not a matching
  symlink, and `install.sh:36` aborts when `$CONFIG` is missing. The Claude Code
  part must be optional so a machine without Claude Code still installs.
- `install.sh` user-facing output is German. The repo keeps prompts and plans in
  English but installer messages German; keep that split.
- `README.md:3` — "Two opencode agents: **thot** plans, **imhotep** builds."
  This sentence no longer covers the Claude Code target.
- `jq` is available at `/usr/bin/jq`.
- Claude Code version at plan time: `2.1.266`. `claude plugin validate <dir>`
  exists and requires v2.1.233 or later.

## Decisions

- **D1: Deliver as `claude --agent thot`, not as an output style** — see `review-context`.
- **D2: Replace the hard edit lock with ask-by-default** — see `review-context`.
- **D3: Use the relative anchor `Edit(docs/plans/**)`** — see `review-context`.
- **D4: Maintain two independent prompt files** — see `review-context`.
- **D5: context7 is a documented manual prerequisite** — see `review-context`.
- **D6: The installer never edits `~/.claude/settings.json`** — see `review-context`.
- **D7: The `## Execution rules` block stays opencode-flavoured, verbatim** — see `review-context`.
- **D8: Drop `scout`, keep `Explore`** — see `review-context`.
- **D9: Only `rg` and `fd` get explicit Bash allow rules** — see `review-context`.
- **D10: `AskUserQuestion` availability is an assumption; the gate degrades gracefully** — see `review-context`.
- **D11: Pin `model: opus`** — see `review-context`.
- **D13: Verification is path-scoped; untracked editor artifacts are out of scope** — see `review-context`.

## Names

New files:
- `claude/agents/thot.md`
- `claude/settings.example.json`

New identifiers:
- Claude Code agent `name`: `thot`
- Symlink target: `~/.claude/agents/thot.md`
- Invocation: `claude --agent thot`
- MCP server name: `context7`
- MCP tool names used in the prompt: `mcp__context7__resolve-library-id`,
  `mcp__context7__query-docs`
- Permission rules: `Edit(docs/plans/**)`, `Bash(rg *)`, `Bash(fd *)`
- Installer variable: `CLAUDE_DIR`

## Todos

- [x] 1. Add the Claude Code Thot agent file
      Files: claude/agents/thot.md
      Acceptance: `claude plugin validate claude/agents` reports success. The file
        contains both `mcp__context7__` tool names, `AskUserQuestion`, and
        `Explore`. It contains no `subagent_type`, no `scout`, no bare
        `context7_resolve-library-id` or `context7_query-docs`, no `mode:` and no
        `temperature:` frontmatter key. Exactly one occurrence of the literal
        `` `question` `` remains and it sits inside the `## Execution rules` block.

- [x] 2. Add the example permission snippet
      Files: claude/settings.example.json
      Acceptance: the file is valid JSON, contains the three rules above, and
        contains no `Edit(/docs/plans/**)` form, which would anchor against
        `~/.claude/` when pasted into user settings (D3). RED before the change:
        `grep -c 'Edit(docs/plans/\*\*)' claude/settings.example.json` failed with
        `Datei oder Verzeichnis nicht gefunden`, exit 2.

- [x] 3. Extend the installer with the optional Claude Code target
      Files: install.sh
      Acceptance: a first run creates the symlink; a second run reports it as
        skipped and changes nothing; `claude --agent thot` resolves afterwards.
        RED before the change: `ls -l ~/.claude/agents/thot.md` failed with
        `Datei oder Verzeichnis nicht gefunden`, and `claude --agent thot -p "x"`
        printed `--agent 'thot' not found. Available agents: claude, Explore, general-purpose, Plan, statusline-setup`.

- [x] 4. README: prerequisites and installation for the Claude Code target
      Files: README.md
      Acceptance: README names the exact `claude mcp add` command, the
        `claude --agent thot` invocation, the new symlink row, and the manual
        settings step. RED before the change:
        `grep -c 'claude --agent thot' README.md` printed `0`, exit 1.

- [x] 5. README: workflow, enforcement honesty, and two-file maintenance
      Files: README.md
      Acceptance: README no longer opens with "Two opencode agents", contains a
        `## Claude Code variant` section, names all six prompt deltas, and the
        enforcement table marks the Claude Code edit scope as soft. RED before the
        change: `grep -n 'Two opencode agents' README.md` matched at line 3.

## Final verification

- [x] F1. Plan compliance: every todo implemented as described.
      Path-scoped check:
      `git status --short -- claude/ install.sh README.md docs/plans/thot-claude-code-variant-plan.md docs/plans/thot-claude-code-variant-plan.review-context.md`
      lists exactly `README.md`, `claude/agents/thot.md`,
      `claude/settings.example.json`, `install.sh`, and this plan pair.
      Leak check: `git status --short --untracked-files=no` lists no tracked path
      outside that set. Untracked editor artifacts (`.idea/*`, `*.iml`) are NOT
      plan output and MUST be ignored by this check; do not stage or delete them,
      and do not edit `.gitignore` (see D13).
- [x] F2. Code quality: `bash -n install.sh` exits 0;
      `jq -e . claude/settings.example.json` exits 0;
      `claude plugin validate claude/agents` reports success.
- [x] F3. Scope fidelity: `git diff --stat -- agent/ command/` is empty, proving
      `agent/thot.md`, `agent/imhotep.md`, and `command/start-work.md` were not
      touched; `ls claude/agents/` lists `thot.md` and nothing else, proving no
      Claude Code Imhotep variant was added.
- [x] F4. Prompt drift guard: the `##` section headings of `agent/thot.md` and
      `claude/agents/thot.md` are identical.
      `diff <(grep '^## ' agent/thot.md) <(grep '^## ' claude/agents/thot.md)` -> no output, exit 0.

## Success criteria

- `claude --agent thot` starts a session that identifies itself as Thot, plans
  only, and writes its plan pair into `docs/plans/` of the current project.
- A plan produced in Claude Code is executable unchanged by
  `opencode --agent imhotep` plus `/start-work <slug>`.
- `./install.sh` is idempotent and succeeds both with and without Claude Code
  installed.
- The README states plainly where Claude Code enforcement is weaker than
  opencode's.
