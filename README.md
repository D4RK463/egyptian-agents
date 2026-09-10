# egyptian-agents

Thot and Imhotep plan and build in opencode or Claude Code.

Modeled on the planner/worker split of
[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent), but without
subagent orchestration, team mode, and dual review.

## Prerequisites

Both agents assume these optional/required pieces already exist in opencode or
Claude Code. `install.sh` only links files from this repo and the installed
opencode `caveman` skill.

### Skills

| Skill | Used by | Why | Required |
|---|---|---|---|
| `caveman` | imhotep | Loaded before plan execution. Gates, errors, and final reports stay terse. | yes |

Install opencode skills under `~/.agents/skills/<name>/SKILL.md`. Claude Code
loads skills from `~/.claude/skills/<name>/SKILL.md`; when
`~/.agents/skills/caveman` exists, `install.sh` symlinks it into
`~/.claude/skills/caveman`.

### MCP servers

| Server | Used by | Why | Required |
|---|---|---|---|
| `context7` | thot | Current docs for libraries/frameworks/SDKs/CLIs: `context7_resolve-library-id` then `context7_query-docs`. | yes for external dependencies |

Required installation in `~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.com/mcp",
      "headers": {
        "CONTEXT7_API_KEY": "{env:CONTEXT7_API_KEY}"
      }
    }
  },
  "permission": {
    "context7_*": "deny"
  }
}
```

#### Claude Code

Register context7 manually; `install.sh` does not run this command:

```bash
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp --header "CONTEXT7_API_KEY: $CONTEXT7_API_KEY"
```

### Models

Both agents pin their model. The `github-copilot` provider must be
authenticated (`opencode auth login`):

| Runtime | Agent | Model |
|---|---|---|
| opencode | thot | `github-copilot/claude-opus-5` |
| opencode | imhotep | `github-copilot/gpt-5.6-terra` |
| Claude Code | thot | `opus` |
| Claude Code | imhotep | `sonnet` |

Different provider? Change `model:` in the relevant agent file. Claude Code
variants run on the Anthropic subscription; opencode agents remain on
`github-copilot`.

### CLI tools

thot allowlist contains `rg`, `fd`, `find`, `head`, `tail`, `sed -n`, `wc`, and
read-only `git` commands. `rg` may be absent; use `git grep` or `grep` portably.
`cat` is intentionally not allowlisted to avoid large accidental dumps.

Claude Code auto-approves its built-in read-only Bash set. Only `rg` and `fd`
need explicit allow rules. `cat` is auto-approved there, although opencode
withholds it.

## Installation

```bash
./install.sh
```

Creates symlinks:

| Repo | Target |
|---|---|
| `agent/` | `~/.config/opencode/agent` |
| `command/start-work.md` | `~/.config/opencode/command(s)/start-work.md` |
| `claude/agents/thot.md` | `~/.claude/agents/thot.md` |
| `claude/agents/imhotep.md` | `~/.claude/agents/imhotep.md` |
| `claude/commands/start-work.md` | `~/.claude/commands/start-work.md` |
| `~/.agents/skills/caveman` | `~/.claude/skills/caveman` |

Claude Code step is skipped when `~/.claude` is absent. Paste
`claude/settings.example.json` into `~/.claude/settings.json` manually;
`install.sh` never writes that file.
Start Claude Code planning with `claude --agent thot` or execution with
`claude --agent imhotep`; use `/start-work <slug>` to resume a plan.

Idempotent. Aborts if a target exists and is not a matching symlink.

Restart opencode afterwards; config is loaded at startup.

## Workflow

Plan pair in `docs/plans/` is the only interface. Cross-tool execution works:
plan with `claude --agent thot`, then execute with `opencode --agent imhotep`.
A Claude-Code-only round trip also works: plan with `claude --agent thot`, then
execute with `claude --agent imhotep` and `/start-work <slug>`.

```text
Agent: thot                      Agent: imhotep
───────────                      ──────────────
explores                         loads caveman
asks owner decisions only        reads the plan
waits for your OK                builds first open todo
writes plan + review context     ───>  Gate: review
                                 checkpoint + stop
new session + `/start-work <slug>` -> builds next open todo
                                 Gate: review
                                 checkpoint + stop
                                 ...
restart after all N. done ─────> final verification without gates
                                 final report
```

Use:

```text
switch agent to thot, describe the task
...
switch agent to imhotep (tab or ctrl+x, then a)
/start-work <slug>
```

The plan and its review context are the only interface and state store. Sessions
are disposable. That is why plans must be decision-complete, and later-needed
facts/decisions are persisted back into those files.

## thot — Planner

- Plans only; never implements.
- Hard-enforced edit scope: `docs/plans/**` only.
- Explores before asking and cites findings with `file:line`.
- Uses Context7 for external API/library details.
- Asks only owner decisions: irreversible/security-critical choices, public API
  or config, data/schema, new dependencies, packaging, migrations.
- Requires an approval brief before writing the plan and review context.
- Records every planning decision and assumption separately for future reviews.
- Plan mode is sticky: "do X" means "plan X".

## Claude Code variant

`claude/agents/thot.md` and `claude/agents/imhotep.md` are independently
maintained Claude Code prompts. Edit the Thot pair and Imhotep pair together on
prompt changes; no generator or shared body keeps either pair synchronized.

`claude/commands/start-work.md` resumes plans with `/start-work <slug>`. It uses
`$ARGUMENTS`; opencode's `command/start-work.md` uses 1-based `$1`, while Claude
Code `$1` means the second argument.

Thot prompt deltas: Claude Code uses `Agent` and `Explore` instead of
`task(subagent_type=...)`; it has no `scout`; it uses `mcp__context7__*` tool
names and `AskUserQuestion` instead of `question`; its frontmatter has no
`mode` or `temperature`.

Imhotep prompt deltas: `AskUserQuestion` replaces `question`; `Skill` loads
`caveman`; `claude --agent imhotep` is its identity guard; omitting `Agent`
prevents subagents; frontmatter has no `mode`, `temperature`, or `permission`;
`permissionMode: acceptEdits` accepts edits; Bash accepts a per-call `timeout`
and backgrounds commands that exceed it.

The `## Execution rules` block in generated plans stays opencode-flavoured on
 purpose. Either Imhotep variant maps its tool names when executing it.

## imhotep — Worker

- Verifies it is the active agent before reading or writing.
- Loads `caveman` before plan execution; output stays terse.
- On each `/start-work`, skips checked todos and executes only the first open
  implementation todo `N.`.
- After that todo: implement, run listed QA, stop, call `question`, wait for
  `weiter` / `continue` / `ok` / `go`.
- On approval: persists later-needed facts/decisions in the plan and review
  context, checks off the todo, reminds you to start a NEW session for token
  savings, prints the next `/start-work <slug>`, and stops. Running `/start-work` in the same chat works,
  but does not save as much context.
- Final verification tasks `F<n>` run without gates once all `N.` todos are
  checked. imhotep stops only on failure; otherwise it gives one final report.
- No commits and no commit suggestions. Opencode blocks commit/history-changing
  commands via `permission.bash`; Claude Code keeps this as a prompt rule.
- If the plan is wrong, imhotep stops and hands back to thot instead of
  improvising.

## Language

Prompts and plan files use English for stronger instruction compliance and lower
token use. User-facing chat responses follow the user's latest language; only
fixed markers like `THOT: PLAN MODE`, code, commands, paths, and plan files stay
English. Review gate triggers accept both German and English continuation words.

## Switching agents

The `agent:` field in command frontmatter does not switch a `primary` agent;
the command prompt runs under the currently active agent.

| Method | Action |
|---|---|
| Cycle | Press `tab` (`agent_cycle`) |
| Select | Press `ctrl+x`, then `a` (`agent_list`) |
| New session | Run `opencode --agent imhotep` |

Without switching, `/start-work` can run with thot's permissions. Identity
guards in imhotep and the command abort before plan execution.

## Plan and review-context format

Every new plan creates this pair:

```text
docs/plans/<slug>-plan.md
docs/plans/<slug>-plan.review-context.md
```

`<slug>` is lowercase kebab-case and excludes the suffix; `/start-work <slug>`
resolves the corresponding `<slug>-plan.md` file. Every plan filename therefore
ends in `-plan.md`.

The plan remains the execution contract:

```text
## TL;DR
## Execution rules      <- copied into every plan
## Scope                In / Out / Must-NOT-Have
## Findings             facts with file:line
## Decisions            concise summary with D<n> references
## Todos                - [ ] N.  at column 0
## Final verification   - [ ] F<n>.  at column 0
## Success criteria
```

The review context is the canonical decision/assumption record for reviewers.
Each `D<n>` entry records its status (`confirmed`, `assumption-to-verify`, or
`superseded`), rationale, evidence, rejected alternatives, and constraints or
validity. A reviewer must read it before proposing changes and may reverse a
recorded decision only with new, concrete evidence. Older plans may not have a
review-context file.

Task lines must be exactly `- [ ] N.` or `- [ ] F<n>.` at column 0. Target 5–8
implementation todos. Implementation and test are one todo.

Current execution rule summary:

1. Load `caveman` first.
2. No commits or history changes.
3. Each session executes only the first unchecked implementation todo `N.`.
4. Gate after that todo, then checkpoint and stop on approval.
5. Final verification `F<n>` runs without gates unless it fails.
6. `Must-NOT-Have` is binding.
7. Plan wrong or reality differs: stop and return to thot.

## What is hard-enforced

| Mechanism | Enforcement |
|---|---|
| opencode `permission.edit`, `permission.bash` | hard when matching agent is active |
| Claude Code edit scope | soft: `Edit(docs/plans/**)` is allowed; all other edits are ask-by-default, not denied |
| opencode `question` blocks the turn | hard |
| Claude Code `AskUserQuestion` blocks the turn | unverified; text brief plus end-of-turn remains fallback |
| model, temperature | hard where agent runtime supports them |
| Claude Code commit lock | soft: prompt-only; agent frontmatter cannot carry Bash rules, and settings rules apply to every session |
| caveman style, step gate, fresh-session flow, scope guard, final-verification flow | soft model instruction |
| `## Execution rules` in the plan | soft, but survives compaction |

OpenCode commit lock is real. Claude Code commit lock is prompt-only. Other core
rules are discipline, so they live both in the agent prompt and every plan.

## Deliberately omitted

Team mode, dual review, separate plan review agents, SHA256 round contracts,
draft state, scaffold script, category routing, and lifecycle hooks. With two
sequential agents they mostly cost prompt budget.
