# thot-claude-code-variant — Review Context

## Purpose
Read this before reviewing the plan or implementation. Do not propose changes
that reverse a recorded decision without new, concrete evidence.

## Decisions and assumptions

### D1. Deliver the Claude Code variant as `claude --agent thot`, not as an output style
- **Status:** confirmed
- **Rationale:** `agent/thot.md:3` declares `mode: primary`. Claude Code offers
  three candidate mechanisms: a subagent, an output style, and an agent file run
  as the main session. Only the third replaces the system prompt *and* carries
  `model`, `tools`, and `permissionMode`. Output styles carry none of those, and
  a plain subagent cannot be the main conversation and loses `AskUserQuestion`
  outright.
- **Evidence:** https://docs.claude.com/en/docs/claude-code/sub-agents — "Pass
  `--agent <name>` to start a session where the main thread itself takes on that
  subagent's system prompt, tool restrictions, and model" and "The subagent's
  system prompt replaces the default Claude Code system prompt entirely".
  https://docs.claude.com/en/docs/claude-code/output-styles — frontmatter is
  limited to `name`, `description`, `keep-coding-instructions`, and
  `force-for-plugin`.
- **Rejected alternatives:** Output style (no model pin, no tool restriction, no
  permission mode). Slash command (does not replace the system prompt; the
  default Claude Code coding prompt would keep pulling the session toward
  implementing). Plain subagent (`AskUserQuestion` is filtered out of every
  subagent, and the user cannot converse with it directly).
- **Constraints / validity:** Valid for Claude Code 2.1.266. An earlier
  conversational answer suggested an output style; that suggestion is wrong and
  is superseded here.

### D2. Replace the hard edit lock with ask-by-default
- **Status:** confirmed
- **Rationale:** `agent/thot.md:8-11` denies all edits and re-allows
  `docs/plans/**`. Claude Code evaluates deny before ask before allow and states
  explicitly that a deny rule cannot carry allowlist exceptions, so the same
  shape would also block plan writing. The remaining faithful option is to allow
  only `Edit(docs/plans/**)` and let every other edit hit the default permission
  prompt, which the user can refuse. The user chose this over a source-path deny
  list.
- **Evidence:** https://docs.claude.com/en/docs/claude-code/permissions —
  "Rules are evaluated in order: deny, then ask, then allow" and "a deny rule
  can't carry allowlist exceptions".
- **Rejected alternatives:** A deny list for typical source paths (`src/**`,
  `*.ts`, `pom.xml`, ...) — incomplete by construction and therefore false
  safety; the user rejected it. `permissionMode: plan` — blocks source edits but
  would also block writing the plan pair, which is Thot's only job. Withholding
  `Edit`/`Write` entirely — breaks the file-based handoff to Imhotep.
- **Constraints / validity:** This is a real downgrade. In opencode the scope is
  enforced by the runtime; in Claude Code it is a convention plus a prompt the
  user can click through. The README must say so (todo 5), and the guarantee
  must not be claimed anywhere else.

### D3. Use the relative anchor `Edit(docs/plans/**)`, never `Edit(/docs/plans/**)`
- **Status:** confirmed
- **Rationale:** The rules are pasted into `~/.claude/settings.json` so they
  apply in every project. A leading `/` anchors at the settings source, which for
  user settings is `~/.claude/`, so `Edit(/docs/plans/**)` would grant access to
  `~/.claude/docs/plans/` and to nothing in any project. The bare relative form
  resolves against the current directory, which is what a per-project
  `docs/plans/` needs.
- **Evidence:** https://docs.claude.com/en/docs/claude-code/permissions —
  table row "User settings at `~/.claude/settings.json`" -> "`~/.claude/path`",
  and "A pattern like `/Users/alice/file` isn't an absolute path".
- **Rejected alternatives:** `Edit(/docs/plans/**)` — silently wrong.
  `Edit(**/docs/plans/**)` — also matches nested vendor copies; unnecessary
  width for an allow rule.
- **Constraints / validity:** Only correct while the rules live in user
  settings. If they are ever moved into a project's `.claude/settings.json`, the
  anchor changes and this entry must be revisited.

### D4. Maintain two independent prompt files
- **Status:** confirmed
- **Rationale:** The bodies must diverge in roughly eight places (tool names,
  `scout`, frontmatter). The user chose two reviewable files in git over a
  generator. A `sed`-based transformation of prompt prose is brittle and its
  output would not be reviewable in git.
- **Evidence:** `agent/thot.md:59`, `:62`, `:63-64`, `:83` are the diverging
  lines; `agent/thot.md:1-28` is the diverging frontmatter.
- **Rejected alternatives:** Shared body plus install-time generation — single
  source, but unreviewable output and fragile text substitution.
- **Constraints / validity:** Drift is the accepted cost. Todo 5 documents the
  obligation to edit both files; `F4` adds a mechanical guard that both files
  carry identical `##` headings. That guard catches structural drift only, not
  wording drift.

### D5. context7 is a documented manual prerequisite, not installer work
- **Status:** confirmed
- **Rationale:** The README already documents the opencode context7 setup as a
  prerequisite the installer does not perform. Mirroring that for Claude Code
  keeps one consistent rule and keeps the installer free of credential handling.
- **Evidence:** `README.md` section "MCP servers" documents the required
  `~/.config/opencode/opencode.json` block as a prerequisite; `install.sh` never
  touches it.
- **Rejected alternatives:** Inline `mcpServers` in the agent frontmatter —
  attractive because it keeps context7 out of unrelated Claude Code sessions, but
  whether `{env:...}`-style indirection for the API key works there is
  undocumented, and the docs add a folder-trust condition for inline servers.
  Not worth an unverified dependency in the core prompt file.
- **Constraints / validity:** `claude mcp add --scope user` stores the header
  value in `~/.claude.json`. The user accepted the plaintext key. If that becomes
  unacceptable, revisit the inline option and verify env expansion first.

### D6. The installer never edits `~/.claude/settings.json`
- **Status:** confirmed
- **Rationale:** `install.sh:2-3` states the invariant "Fasst nichts an, was kein
  Symlink ist". Merging permission rules into an existing settings file that
  already holds unrelated keys would break it. Shipping
  `claude/settings.example.json` keeps the rules under review in git while the
  user stays in control of their own settings file.
- **Evidence:** `install.sh:2-3` (stated invariant); `~/.claude/settings.json`
  currently contains `{"theme": "light"}`, i.e. unrelated user state.
- **Rejected alternatives:** `jq`-based merge — would silently rewrite user
  settings and contradicts the installer's own contract. Printing the JSON only
  in the heredoc — not reviewable in git and easy to mistype.
- **Constraints / validity:** The user must perform one manual paste. The
  installer heredoc reminds them.

### D7. The `## Execution rules` block stays opencode-flavoured, byte for byte
- **Status:** confirmed
- **Rationale:** That block is copied into every generated plan and is executed
  by Imhotep in opencode. It references `skill(name="caveman")` and the opencode
  `question` tool. Translating it into Claude Code vocabulary would break plan
  execution. This is the single most likely well-meant mistake during
  implementation, so it is called out in Scope, Must-NOT-Have, the todo steps,
  and the QA.
- **Evidence:** `agent/thot.md:143-152` is the block; `agent/imhotep.md`
  consumes it. `agent/thot.md` contains exactly two occurrences of the literal
  `` `question` ``: line 83 (Thot's own instruction, must change) and line 147
  (inside the block, must not change).
- **Rejected alternatives:** Making the block tool-agnostic — would weaken the
  instructions Imhotep relies on and is out of scope for this plan.
- **Constraints / validity:** The QA in todo 1 asserts exactly one remaining
  `` `question` `` occurrence and that it is the Execution-rules line. If the
  block is ever reworded in `agent/thot.md`, that count changes and the QA must
  be updated.

### D8. Drop `scout`, keep `Explore`
- **Status:** confirmed
- **Rationale:** `agent/thot.md:62` delegates dependency-source inspection to an
  opencode subagent named `scout`. Claude Code has no such agent, and an
  unresolvable delegation instruction would make Thot burn turns on a failing
  tool call.
- **Evidence:** Observed output of `claude --agent thot -p "x"`:
  `--agent 'thot' not found. Available agents: claude, Explore, general-purpose, Plan, statusline-setup`.
  https://docs.claude.com/en/docs/claude-code/sub-agents lists the built-ins
  Explore, Plan, general-purpose, claude, statusline-setup, claude-code-guide.
- **Rejected alternatives:** Writing a custom `scout` subagent for Claude Code —
  scope creep; the user asked for a Thot variant only. Mapping `scout` to
  `general-purpose` — that agent can write, which contradicts Thot's read-only
  posture.
- **Constraints / validity:** The Claude Code variant loses the ability to clone
  a dependency that is not already on disk. The replacement instruction is to say
  so and fall back to context7. This is a capability difference, not a bug.

### D9. Only `rg` and `fd` get explicit Bash allow rules
- **Status:** confirmed
- **Rationale:** `agent/thot.md:13-26` allowlists `ls`, `rg`, `fd`, `find`, `wc`,
  `head`, `tail`, `sed -n`, and read-only `git`. Claude Code auto-approves most of
  these already, so replicating the full list would be noise.
- **Evidence:** https://docs.claude.com/en/docs/claude-code/permissions, section
  "Read-only commands": the built-in set includes `ls`, `cat`, `echo`, `pwd`,
  `head`, `tail`, `grep`, `find`, `wc`, `which`, `diff`, `stat`, `du`, `cd`, and
  read-only forms of `git`.
- **Rejected alternatives:** Restating every rule — redundant and misleading,
  since the built-in set is not configurable away by an allow rule anyway.
- **Constraints / validity:** `cat` is auto-approved in Claude Code although
  `README.md` records that opencode withholds it deliberately to avoid large
  accidental dumps. That protection does not exist in the Claude Code variant and
  todo 4 documents it. `sed -n` is not in the built-in set and will prompt; that
  is acceptable.

### D10. `AskUserQuestion` availability in a main-session agent is an assumption
- **Status:** assumption-to-verify
- **Rationale:** Claude Code documents a filter that removes `AskUserQuestion`
  from *every subagent*. An agent file running as the main session via `--agent`
  is not a spawned subagent, so the filter should not apply, but the docs do not
  say so explicitly. A headless probe could not settle it because `-p` mode
  removes interactive tools regardless.
- **Evidence:** https://docs.claude.com/en/docs/claude-code/sub-agents, section
  "Available tools": "The first filter removes these tools, even when listed in
  the `tools` field: ... `AskUserQuestion` ...". Probe executed at plan time:
  `claude --agents '{"probe":{...}}' --agent probe -p "List every tool name available to you."`
  returned `Agent, Bash, Edit, ListAgents, Read, ReportFindings, ScheduleWakeup, ShareOnboardingGuide, Skill, ToolSearch, Workflow, Write`
  — no `AskUserQuestion`, but also no `Grep`, `Glob`, `WebFetch`, or `TodoWrite`,
  which shows the result reflects headless mode and lazy `ToolSearch` loading
  rather than the `--agent` path.
- **Rejected alternatives:** Blocking the plan on an interactive probe — cannot
  be automated from this session. Removing `AskUserQuestion` from the `tools`
  list pre-emptively — would guarantee the weaker behaviour instead of merely
  tolerating it.
- **Constraints / validity:** The risk is contained. In opencode `question`
  blocks the turn; in Claude Code, ending a turn already returns control to the
  user, so the approval gate survives either way. The prompt therefore instructs
  Thot to fall back to a text brief plus end-of-turn. Listing an unresolvable
  tool is safe: Claude Code refuses to launch only when *no* entry in `tools`
  resolves. Verify in the first real interactive session and update this entry's
  status.

### D11. Pin `model: opus`
- **Status:** confirmed
- **Rationale:** The stated motivation for the whole change is to move planning
  onto the Anthropic subscription while Imhotep keeps running on
  `github-copilot/gpt-5.6-terra`. `opus` is the family alias matching the
  existing `github-copilot/claude-opus-5` pin.
- **Evidence:** `agent/thot.md:4` pins `github-copilot/claude-opus-5`;
  https://docs.claude.com/en/docs/claude-code/sub-agents accepts `sonnet`,
  `opus`, `haiku`, `fable`, a full model ID, or `inherit`.
- **Rejected alternatives:** `inherit` — would silently follow whatever the
  session default is and lose the pin. A full model ID such as `claude-opus-5` —
  pins harder but rots on the next model release.
- **Constraints / validity:** If the subscription tier does not permit Opus,
  Claude Code substitutes the newest permitted model of that family and warns.
  Acceptable.

### D12. No Claude Code variant of Imhotep
- **Status:** confirmed
- **Rationale:** The user asked for a Thot variant only. Imhotep's value rests on
  hard `permission.bash` deny rules for commit and history commands, which
  opencode enforces per agent. In Claude Code those rules would have to live in
  global settings and would then also constrain every other session.
- **Evidence:** `agent/imhotep.md:9-21` is the deny block;
  https://docs.claude.com/en/docs/claude-code/sub-agents lists the supported
  frontmatter fields and includes `permissionMode` but no per-agent permission
  rule set.
- **Rejected alternatives:** Porting Imhotep too — would either lose the commit
  lock or impose it globally.
- **Constraints / validity:** Execution stays in opencode. This is what makes the
  split coherent: planning on the subscription, execution under the stricter
  runtime.

### D13. Verification is path-scoped; untracked editor artifacts are out of scope
- **Status:** confirmed
- **Rationale:** F1 originally read a bare `git status --short` over the whole
  worktree, so unrelated IntelliJ artifacts blocked final verification even
  though every todo was implemented correctly. A compliance check must measure
  plan output, not ambient worktree noise.
- **Evidence:** `.idea/.gitignore` — tracked, but ignores only `/shelf/`,
  `/workspace.xml`, `/httpRequests/`, `/queries/`, `/dataSources*`; therefore
  `.idea/misc.xml`, `.idea/modules.xml`, `.idea/vcs.xml` and `agents.iml` show as
  untracked. `git status --short --untracked-files=no` lists exactly the five
  plan-owned tracked paths, proving no todo produced them.
- **Rejected alternatives:** (a) Adding `.idea/` and `*.iml` to `.gitignore` —
  repo-wide VCS policy change, outside this plan's scope and an owner decision in
  its own right; the user explicitly declined it. (b) Using only
  `--untracked-files=no` — would also hide the untracked
  `*-plan.review-context.md`, which IS plan output and must be verified.
- **Constraints / validity:** Valid while the plan's output set is
  `claude/`, `install.sh`, `README.md` and the plan pair. If a later amendment
  adds files, the F1 path list must be extended with them.
