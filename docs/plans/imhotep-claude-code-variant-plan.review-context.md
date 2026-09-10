# imhotep-claude-code-variant — Review Context

## Purpose
Read this before reviewing the plan or implementation. Do not propose changes
that reverse a recorded decision without new, concrete evidence.

## Decisions and assumptions

### D1. Deliver as `claude --agent imhotep`, mirroring the Thot variant
- **Status:** confirmed
- **Rationale:** opencode's `mode: primary` has no Claude Code equivalent. Only a
  main-session agent launched with `--agent` replaces the system prompt and
  carries `model`, `tools`, and `permissionMode`. The same mechanism already
  ships for Thot, so the Imhotep variant stays symmetric and needs no new concept.
- **Evidence:** `agent/imhotep.md:3` — `mode: primary`;
  `claude/agents/thot.md:1-7` — the working precedent;
  https://code.claude.com/docs/en/sub-agents, "Supported frontmatter fields".
- **Rejected alternatives:** an output style (cannot restrict tools or pin a
  model); a plugin (adds a marketplace and manifest for two files); a subagent
  invoked from a Thot session (subagents lose `AskUserQuestion`, which the review
  gate depends on).
- **Constraints / validity:** valid for Claude Code v2.1.266. If `--agent` ever
  stops replacing the system prompt, the whole variant needs rework.

### D2. Pin `model: sonnet`
- **Status:** confirmed
- **Rationale:** user decision. opencode pins `github-copilot/gpt-5.6-terra`,
  which does not exist on the Anthropic subscription. Imhotep executes a
  decision-complete plan rather than designing one, so the cheaper worker model
  matches the role; Thot stays on `opus`.
- **Evidence:** `agent/imhotep.md:4` — `model: github-copilot/gpt-5.6-terra`;
  `claude/agents/thot.md:4` — `model: opus`;
  https://code.claude.com/docs/en/sub-agents, "Choose a model".
- **Rejected alternatives:** `opus` (higher cost for mechanical execution);
  `inherit` (no reproducibility across sessions, and the plan's success depends
  on stable execution behaviour).
- **Constraints / validity:** if gate quality degrades on `sonnet`, changing the
  single `model:` line is the fix; no other file depends on it.

### D3. No hard commit lock; the commit rule stays a prompt instruction
- **Status:** confirmed
- **Rationale:** user decision after being shown the trade-off. Claude Code agent
  frontmatter has no field for Bash permission rules, and rules placed in
  `~/.claude/settings.json` apply to every Claude Code session on the machine,
  including plain `claude` and `claude --agent thot`. The user rejected that
  blast radius. `permissionMode: acceptEdits` still leaves every Bash command
  prompting, so a `git commit` surfaces an interactive prompt as a practical, if
  not guaranteed, backstop.
- **Evidence:** `agent/imhotep.md:10-23` — the opencode deny list;
  https://code.claude.com/docs/en/sub-agents, "Supported frontmatter fields" (no
  permissions field); https://code.claude.com/docs/en/permissions, "Settings
  precedence"; the same page notes at "What a Bash rule doesn't match" that
  `git -C . push` evades `Bash(git push *)`, so even the settings-based lock
  would be partial.
- **Rejected alternatives:** deny rules in `claude/settings.example.json`
  (rejected by the user: machine-wide); a project-level `.claude/settings.json`
  (the agents are user-scoped and must work in every repository).
- **Constraints / validity:** this is the single largest enforcement gap versus
  opencode and must be stated in the README enforcement table. Revisit only if
  Claude Code adds per-agent permission rules.

### D4. No hooks in the agent frontmatter
- **Status:** confirmed
- **Rationale:** a `PreToolUse` hook could block commits agent-scoped, but the
  documentation defines frontmatter hooks for subagents ("only while that
  subagent is running") and does not state that they register for an agent
  running as the main session via `--agent`. The `mcpServers` field carries an
  explicit note that it applies in both contexts; `hooks` carries no such note.
  Shipping an unverified enforcement mechanism plus a shell script is worse than
  a documented soft rule.
- **Evidence:** https://code.claude.com/docs/en/hooks, "Hooks in skills and
  agents"; https://code.claude.com/docs/en/sub-agents, the `mcpServers` note that
  explicitly covers the `--agent` case while the `hooks` row does not.
- **Rejected alternatives:** a `PreToolUse: Bash` hook running a deny script.
- **Constraints / validity:** if a future release documents frontmatter hooks for
  main-session agents, this is the natural way to restore the hard commit lock
  without machine-wide settings, and D3 should be revisited together with it.

### D5. `install.sh` links `~/.agents/skills/caveman` into `~/.claude/skills/`
- **Status:** confirmed
- **Rationale:** Imhotep's first action is loading `caveman`, and its preflight
  reports a missing skill as `Class: env`. Claude Code reads personal skills only
  from `~/.claude/skills/`, which does not exist on this machine, so a Claude
  Code Imhotep would fail its own preflight on a fresh install. Claude Code
  explicitly supports a symlinked skill directory, and `install.sh` already
  creates directories and symlinks under `~/.claude`, so this reuses `link()`
  without new machinery.
- **Evidence:** `agent/imhotep.md:33-42` — the mandatory `caveman` load;
  `agent/imhotep.md:44-50` — preflight classifies a missing skill as `Class: env`;
  `README.md:20` — skills are installed under `~/.agents/skills/<name>/SKILL.md`;
  `ls -ld ~/.claude/skills` failed with `Datei oder Verzeichnis nicht gefunden`;
  https://code.claude.com/docs/en/skills, "Choose where skills load" (symlinked
  folders supported).
- **Rejected alternatives:** documenting caveman as a manual Claude Code
  prerequisite only (the Thot precedent D5 for context7), rejected because
  context7 is optional for Thot while caveman is mandatory for Imhotep; copying
  the skill into the repository (creates a second source of truth for a file this
  repo does not own).
- **Constraints / validity:** the link is created only when
  `~/.agents/skills/caveman` is a directory; otherwise the installer skips it with
  a German note. It never overwrites an existing non-symlink target, because
  `link()` aborts (`install.sh:26`).

### D6. `AskUserQuestion` replaces `question`; the gate degrades to text
- **Status:** assumption-to-verify
- **Rationale:** Claude Code's equivalent of opencode's `question` tool is
  `AskUserQuestion`, and it is available to a main-session agent. Whether it
  blocks the turn as hard as opencode's `question` is not documented, and the
  `askUserQuestionTimeout` setting can even auto-continue an unanswered question.
  The prompt therefore keeps a text fallback: print the gate and end the turn.
- **Evidence:** `agent/imhotep.md:7` — `question: allow`;
  `agent/imhotep.md:69,125` — the two prompt-level uses;
  https://code.claude.com/docs/en/sub-agents, "Available tools" (stripped from
  subagents, not from the main session);
  https://code.claude.com/docs/en/tools-reference, "Question auto-continue
  timeout"; `claude/agents/thot.md:61` — the same fallback wording already ships.
- **Rejected alternatives:** relying on `AskUserQuestion` alone; ending the turn
  without any structured question.
- **Constraints / validity:** verify in the first real Claude Code Imhotep run
  that the gate actually stops execution. If `askUserQuestionTimeout` is set in
  user settings, a gate can auto-continue — call that out if it is ever observed.

### D7. The Claude Code command file uses `$ARGUMENTS`, not `$1`
- **Status:** confirmed
- **Rationale:** Claude Code substitution is 0-based, so `$1` is the second
  argument; the opencode command's `$1` would silently resolve to nothing.
  `/start-work` takes exactly one argument, so `$ARGUMENTS` is both correct and
  unambiguous. The file also cannot carry opencode's `agent:` frontmatter field,
  which does not exist in Claude Code, so the identity guard must live in the
  command body and in the agent prompt.
- **Evidence:** `command/start-work.md:6` — opencode's `$1`;
  https://code.claude.com/docs/en/skills, "Available string substitutions"
  (`$N` is shorthand for `$ARGUMENTS[N]`, `$0` is the first argument);
  the same page, "Command files" (`.claude/commands/` supports the same
  frontmatter except `name` and `paths`).
- **Rejected alternatives:** `$0` (correct but easy to mistake for a shell
  idiom); symlinking `command/start-work.md` into `~/.claude/commands/` (would
  ship the wrong substitution and an ignored `agent:` key); writing the command as
  a skill folder (more files for no gain).
- **Constraints / validity:** holds while `/start-work` takes exactly one
  argument. A second argument would force named `arguments:` frontmatter.

### D8. The `## Execution rules` block stays opencode-flavoured, verbatim
- **Status:** confirmed
- **Rationale:** the block is copied verbatim into every plan and is executed by
  whichever Imhotep runs. Rewriting it per tool would fork the plan format and
  break plans written by the opencode Thot. Instead the Claude Code Imhotep prompt
  states the mapping: `skill(name="caveman")` means the `Skill` tool with
  `caveman`, and `question` means `AskUserQuestion`.
- **Evidence:** `agent/thot.md:142` and `claude/agents/thot.md:120` — both Thot
  variants emit the identical block; `docs/plans/thot-claude-code-variant-plan.md:47`
  — the same rule already recorded as a Must-NOT-Have.
- **Rejected alternatives:** a tool-specific execution-rules block; a per-tool
  plan dialect.
- **Constraints / validity:** any change to the block must be mirrored in both
  Thot files, otherwise plans drift apart.

### D9. `permissionMode: acceptEdits` plus adapted timeout wording
- **Status:** confirmed
- **Rationale:** the opencode Imhotep may edit freely and runs bash freely except
  for the git denials. `acceptEdits` reproduces the free editing while keeping a
  prompt on Bash commands, which is the only remaining brake after D3. The
  timeout paragraph must change because Claude Code does not fail a timed-out
  command: it moves it to the background, so the opencode wording would make
  Imhotep misread a normal long build.
- **Evidence:** `agent/imhotep.md:10-11` — bash allowed by default, no edit
  restriction; `agent/imhotep.md:162-164` — the opencode timeout paragraph;
  https://code.claude.com/docs/en/sub-agents, "Permission modes";
  https://code.claude.com/docs/en/tools-reference, "Timeout and output limits"
  (default two minutes, ceiling ten minutes, auto-backgrounding with the message
  `Command did not complete within its 120s timeout and was moved to the background`).
- **Rejected alternatives:** `default` (a prompt per edit makes the worker
  unusable); `bypassPermissions` (removes the last brake against commits, which
  D3 already leaves soft); `dontAsk` (auto-denies and would also deny
  `AskUserQuestion`, breaking the gate).
- **Constraints / validity:** `acceptEdits` auto-accepts edits only inside the
  working directory and `additionalDirectories`.

### D10. Maintain two independent prompt files
- **Status:** confirmed
- **Rationale:** the same choice already made for Thot. A generator or shared
  body would add build tooling to a repository whose whole content is four
  Markdown files and one installer. The drift risk is contained by the F4 heading
  guard and by an explicit README note.
- **Evidence:** `docs/plans/thot-claude-code-variant-plan.md:46` — the same
  Must-NOT-Have; `README.md:152-161` — the existing two-file maintenance note;
  `docs/plans/thot-claude-code-variant-plan.md:190-192` — the existing heading
  drift guard.
- **Rejected alternatives:** a `sed`-based transformation; a shared include file;
  a build step.
- **Constraints / validity:** F4 compares only `## ` headings, not body text. Body
  drift stays a human responsibility.

### D11. Verification is path-scoped; untracked editor artifacts are out of scope
- **Status:** confirmed
- **Rationale:** the worktree carries untracked `.idea/*` and `agents.iml` files
  that predate this plan. A bare `git status --short` check would flag them and
  push Imhotep into deleting or gitignoring files it does not own.
- **Evidence:** `git status --short` at plan time listed `?? .idea/misc.xml`,
  `?? .idea/modules.xml`, `?? .idea/vcs.xml`, `?? agents.iml`;
  `docs/plans/thot-claude-code-variant-plan.md:179-182` — the same rule already
  applied once.
- **Rejected alternatives:** staging the artifacts; adding them to `.gitignore`
  (a repository-owner decision unrelated to this plan).
- **Constraints / validity:** F1 must stay path-scoped for as long as those
  untracked files exist.
