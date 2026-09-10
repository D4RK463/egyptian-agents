# imhotep-claude-code-variant — Work Plan

## TL;DR
What you get: a second, independently maintained Imhotep prompt that runs as the
main session in Claude Code (`claude --agent imhotep`), a Claude Code
`/start-work` command, an extended installer that also links the `caveman` skill
into `~/.claude/skills/`, and a README that documents the Claude-Code-only
workflow and its weaker commit enforcement. / Why this approach: it mirrors the
already-shipped `claude/agents/thot.md` variant, so Claude Code becomes a
complete plan-and-build environment without touching the opencode agents. / What
it does NOT do: no hard commit lock, no deny rules in
`claude/settings.example.json`, no writes into `~/.claude/settings.json`, no
hooks, no generator, no change to `agent/*.md` or `command/start-work.md`. /
Effort: medium. / Risk: low — every change is additive.

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
- New `claude/agents/imhotep.md`: Claude Code frontmatter plus the Imhotep prompt
  body with Claude Code tool names, invocation, and timeout semantics.
- New `claude/commands/start-work.md`: Claude Code slash command that resumes a
  plan under Imhotep.
- `install.sh`: additional optional symlinks for `~/.claude/agents/imhotep.md`,
  `~/.claude/commands/start-work.md`, and `~/.claude/skills/caveman`.
- `README.md`: prerequisites, installation table, workflow, enforcement honesty,
  and the two-file maintenance note for the Imhotep pair.

**Out:**
- Any behaviour change to the opencode agents or the opencode workflow.
- Automating `claude mcp add`.
- Automating edits to `~/.claude/settings.json`.

**Must-NOT-Have:**
- Edits to `agent/thot.md`, `agent/imhotep.md`, or `command/start-work.md`.
- Deny rules or any other change inside `claude/settings.example.json` (D3).
- Writing into `~/.claude/settings.json` or `~/.claude.json` from `install.sh`.
- Hooks in the agent frontmatter (D4).
- A generator, a shared prompt body, or any `sed`-based prompt transformation.
- Translating the `## Execution rules` block into Claude Code vocabulary (D8).
- Changing `claude/agents/thot.md`.

## Findings

- `agent/imhotep.md:3` — `mode: primary`. Claude Code has no `mode` field. The
  equivalent is running the agent file as the main session via
  `claude --agent imhotep`; the agent's system prompt then replaces the Claude
  Code system prompt entirely, and its `model`, `tools`, `permissionMode` apply.
  Source: https://code.claude.com/docs/en/sub-agents, "Supported frontmatter
  fields".
- Claude Code agent frontmatter supports exactly `name`, `description`, `tools`,
  `disallowedTools`, `model`, `permissionMode`, `maxTurns`, `skills`,
  `mcpServers`, `hooks`, `memory`, `background`, `effort`, `isolation`, `color`,
  `initialPrompt`, `experimental`. There is no field for Bash permission rules
  and no `temperature`. Source: https://code.claude.com/docs/en/sub-agents,
  "Supported frontmatter fields". See D3.
- `agent/imhotep.md:10-23` — `permission.bash` denies `git commit*`,
  `git push*`, `git merge*`, `git rebase*`, `git reset*`, `git cherry-pick*`,
  `git tag*`, `git revert*`, `gh pr create*`, `gh pr merge*`. In Claude Code
  these rules can only live in a settings file, where they apply to every
  session on the machine, not only to Imhotep. Source:
  https://code.claude.com/docs/en/permissions, "Tool-specific permission rules".
  See D3.
- `agent/imhotep.md:8-9` — `task: "*": deny`. In Claude Code the equivalent is
  omitting `Agent` from the `tools` list; without `Agent` the main-session agent
  can spawn no subagents. Source: https://code.claude.com/docs/en/sub-agents,
  "Restrict which subagents can be spawned".
- `agent/imhotep.md:7` — `question: allow`. Claude Code names that tool
  `AskUserQuestion`. It is available to a main-session agent and is stripped only
  from subagents. Source: https://code.claude.com/docs/en/sub-agents, "Available
  tools". See D6.
- `agent/imhotep.md:36` and `agent/imhotep.md:69`, `agent/imhotep.md:125` — the
  literals `skill(name="caveman")` and `` `question` `` appear in the prompt
  body. In the Claude Code variant they become the `Skill` tool with `caveman`
  and `AskUserQuestion`. The identical literals also appear inside every plan's
  `## Execution rules` block, which stays opencode-flavoured. See D8.
- `~/.claude/skills` does not exist on this machine; `ls -ld ~/.claude/skills`
  fails with `Datei oder Verzeichnis nicht gefunden`. The `caveman` skill exists
  only at `~/.agents/skills/caveman/`, which Claude Code does not read. Claude
  Code loads personal skills from `~/.claude/skills/<name>/SKILL.md` and accepts
  a symlinked skill directory there. Source:
  https://code.claude.com/docs/en/skills, "Choose where skills load". See D5.
- Claude Code merged custom commands into skills. A Markdown file in
  `.claude/commands/` still works, is invoked by its file name, and supports the
  same frontmatter except `name` and `paths`. There is no `agent:` frontmatter
  field that switches the main-session agent. Source:
  https://code.claude.com/docs/en/skills, "Choose where skills load" and
  "Frontmatter reference". See D7.
- Claude Code argument substitution is 0-based: `$0` is the first argument and
  `$1` is the second. `command/start-work.md:6` uses opencode's 1-based `$1`, so
  copying that file verbatim would resolve the wrong argument. `$ARGUMENTS`
  expands to all arguments and is unambiguous for a single-argument command.
  Source: https://code.claude.com/docs/en/skills, "Available string
  substitutions". See D7.
- Claude Code's Bash tool takes a per-call `timeout` parameter; the default is
  two minutes (`BASH_DEFAULT_TIMEOUT_MS`) and the ceiling ten minutes
  (`BASH_MAX_TIMEOUT_MS`). On timeout Claude Code moves the command to the
  background instead of stopping it, reporting
  `Command did not complete within its 120s timeout and was moved to the background`.
  Source: https://code.claude.com/docs/en/tools-reference, "Timeout and output
  limits". See D9.
- Claude Code names MCP tools `mcp__<server>__<tool>`; `claude/agents/thot.md:6`
  already uses the server-level form `mcp__context7` in `tools`. Source:
  https://code.claude.com/docs/en/permissions, "MCP".
- `install.sh:51-57` — the Claude Code branch is guarded by
  `[ -d "$CLAUDE_DIR" ]` and links only `claude/agents/thot.md`. `install.sh:13`
  `link()` aborts when the target exists and is not a matching symlink, so every
  new target must go through it.
- `install.sh` user-facing output is German while prompts and plans are English;
  keep that split.
- `README.md:3` — "Thot plans in opencode or Claude Code; Imhotep builds in
  opencode." This sentence becomes wrong once Imhotep also runs in Claude Code.
- `README.md:18` — the skills table lists `caveman` as installed under
  `~/.agents/skills/<name>/SKILL.md`, which is the opencode location only.
- `README.md:256-267` — the enforcement table has a row for the opencode
  `permission.bash` commit lock but no row for Claude Code's commit behaviour.
- `agent/imhotep.md` `## ` headings, in order: `First action`, `Preflight`,
  `Role`, `Flow`, `Review gate format`, `Checkpoint before stop`,
  `Final verification`, `Hard stops`, `No commits`, `Scope guard`, `Stop Rules`.
  The Claude Code variant keeps the same set (F4).
- Claude Code version at plan time: `2.1.266`. `claude plugin validate <dir>`
  exists and requires v2.1.233 or later; it currently reports
  `✔ Validation passed` for `claude/agents`.
- `jq` is available at `/usr/bin/jq`.

## Decisions

- **D1: Deliver as `claude --agent imhotep`, mirroring the Thot variant** — see `review-context`.
- **D2: Pin `model: sonnet`** — see `review-context`.
- **D3: No hard commit lock; the commit rule stays a prompt instruction** — see `review-context`.
- **D4: No hooks in the agent frontmatter** — see `review-context`.
- **D5: `install.sh` links `~/.agents/skills/caveman` into `~/.claude/skills/`** — see `review-context`.
- **D6: `AskUserQuestion` replaces `question`; the gate degrades to text** — see `review-context`.
- **D7: The Claude Code command file uses `$ARGUMENTS`, not `$1`** — see `review-context`.
- **D8: The `## Execution rules` block stays opencode-flavoured, verbatim** — see `review-context`.
- **D9: `permissionMode: acceptEdits` plus adapted timeout wording** — see `review-context`.
- **D10: Maintain two independent prompt files** — see `review-context`.
- **D11: Verification is path-scoped; untracked editor artifacts are out of scope** — see `review-context`.

## Names

New files:
- `claude/agents/imhotep.md`
- `claude/commands/start-work.md`

New identifiers:
- Claude Code agent `name`: `imhotep`
- Symlink targets: `~/.claude/agents/imhotep.md`,
  `~/.claude/commands/start-work.md`, `~/.claude/skills/caveman`
- Invocation: `claude --agent imhotep`
- Command invocation: `/start-work <slug>`
- Skill name used in the prompt: `caveman`
- Tool names used in the prompt: `AskUserQuestion`, `Skill`, `TodoWrite`,
  `mcp__context7__resolve-library-id`, `mcp__context7__query-docs`
- Installer variables: `CLAUDE_CMD_DIR`, `CLAUDE_SKILLS_DIR`, `CAVEMAN_SRC`
  (`CLAUDE_DIR` already exists at `install.sh:51`)

## Todos

- [x] 1. Add the Claude Code Imhotep agent file
      Files: claude/agents/imhotep.md
      Acceptance: `claude plugin validate claude/agents` reports success. The file
        contains `AskUserQuestion` at least twice, contains `claude --agent imhotep`,
        contains both `mcp__context7__` tool names, and contains no
        `skill(name="caveman")`, no bare `context7_resolve-library-id` or
        `context7_query-docs`, no `mode:`, no `temperature:`, no `permission:`,
        and no `Agent` entry in `tools:`. Zero occurrences of the literal
        `` `question` `` remain.
        RED before the change: `ls claude/agents/imhotep.md` failed with
        `Datei oder Verzeichnis nicht gefunden`, and `claude --agent imhotep -p "x"`
        printed
        `--agent 'imhotep' not found. Available agents: claude, Explore, general-purpose, Plan, statusline-setup, thot`.
- [x] 2. Add the Claude Code start-work command
      Files: claude/commands/start-work.md
      Acceptance: the file exists, contains `$ARGUMENTS` at least twice, contains
        `claude --agent imhotep`, and contains no `$1` and no `agent:` frontmatter
        key.
        RED before the change: `ls claude/commands` failed with
        `Datei oder Verzeichnis nicht gefunden`.

- [x] 3. Extend the installer with the new Claude Code targets
       Files: install.sh (edited); claude/agents/imhotep.md and
         claude/commands/start-work.md are referenced as symlink sources only and
         must not be modified here
       Acceptance: `bash -n install.sh` exits 0. A first `./install.sh` run creates
        `~/.claude/agents/imhotep.md`, `~/.claude/commands/start-work.md`, and
        `~/.claude/skills/caveman`; a second run prints `skip` for each and changes
        nothing; afterwards `claude --agent imhotep -p "reply with OK"` no longer
        prints `--agent 'imhotep' not found`.
        RED before the change: `ls -l ~/.claude/agents/imhotep.md`,
        `ls -l ~/.claude/commands/start-work.md`, and `ls -ld ~/.claude/skills` each
        failed with `Datei oder Verzeichnis nicht gefunden`, and
        `grep -c 'claude/agents/imhotep.md' install.sh` printed `0`, exit 1.
      QA: happy: `bash -n install.sh` -> exit 0
          happy: `./install.sh && ./install.sh` -> second run prints `skip` for the three new targets, exit 0
          happy: `ls -l ~/.claude/agents/imhotep.md ~/.claude/commands/start-work.md ~/.claude/skills/caveman` -> three symlinks into this repo or into `~/.agents/skills`
          failure: `claude --agent imhotep -p "reply with OK"` -> output does not contain `not found`

- [x] 4. README: prerequisites and installation for the Claude Code Imhotep
      Files: README.md
      Acceptance: README contains `claude --agent imhotep`,
        `~/.claude/skills/caveman`, `~/.claude/commands/start-work.md`, and
        `~/.claude/agents/imhotep.md`.
        RED before the change: `grep -c 'claude --agent imhotep' README.md`
        printed `0`, exit 1.

- [x] 5. README: workflow, enforcement honesty, and two-file maintenance
       Files: README.md
       Acceptance: README no longer contains `Imhotep builds in opencode`, contains
         `permissionMode: acceptEdits`, contains `$ARGUMENTS`, and its enforcement
         table marks the Claude Code commit lock as soft.
       RED before the change: `grep -n 'Imhotep builds in opencode' README.md`
         matched at line 3.

## Final verification

- [x] F1. Plan compliance: every todo implemented as described.
      Path-scoped check:
      `git status --short -- claude/ install.sh README.md docs/plans/imhotep-claude-code-variant-plan.md docs/plans/imhotep-claude-code-variant-plan.review-context.md`
      lists exactly `README.md`, `claude/agents/imhotep.md`,
      `claude/commands/start-work.md`, `install.sh`, and this plan pair.
      Leak check: `git status --short --untracked-files=no` lists no tracked path
      outside that set. Untracked editor artifacts (`.idea/*`, `*.iml`) are NOT
      plan output and MUST be ignored; do not stage or delete them, and do not
      edit `.gitignore` (D11).
- [x] F2. Code quality: `bash -n install.sh` exits 0;
      `jq -e . claude/settings.example.json` exits 0;
      `claude plugin validate claude/agents` reports success.
- [x] F3. Scope fidelity: `git diff --stat -- agent/ command/ claude/settings.example.json`
      is empty, proving `agent/thot.md`, `agent/imhotep.md`,
      `command/start-work.md`, and the settings example were not touched;
      `grep -c 'hooks:' claude/agents/imhotep.md` prints `0`, proving no hook was
      added (D4); `git diff --stat -- claude/agents/thot.md` is empty.
- [x] F4. Prompt drift guard: the `##` section headings of `agent/imhotep.md` and
      `claude/agents/imhotep.md` are identical.
      `diff <(grep '^## ' agent/imhotep.md) <(grep '^## ' claude/agents/imhotep.md)` -> no output, exit 0.

## Success criteria

- `claude --agent imhotep` starts a session that identifies itself as Imhotep,
  loads `caveman`, executes exactly one open implementation todo, and stops at a
  gate.
- `/start-work <slug>` resolves the correct plan file in Claude Code.
- A plan written by either Thot variant is executable unchanged by either Imhotep
  variant.
- `./install.sh` is idempotent and succeeds both with and without Claude Code
  installed.
- The README states plainly that the Claude Code commit lock is prompt-only.
