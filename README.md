# egyptian-agents

Two opencode agents: **thot** plans, **imhotep** builds.

Modeled on the planner/worker split of
[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent), but without
subagent orchestration, team mode, and dual review.

## Prerequisites

Both agents assume these optional/required pieces already exist in opencode.
`install.sh` only links the files from this repo.

### Skills

| Skill | Used by | Why | Required |
|---|---|---|---|
| `caveman` | imhotep | Loaded before plan execution. Gates, errors, and final reports stay terse. | yes |

Install skills under `~/.config/opencode/skills/<name>/SKILL.md`.

### MCP servers

| Server | Used by | Why | Required |
|---|---|---|---|
| `context7` | thot | Current docs for libraries/frameworks/SDKs/CLIs: `resolve-library-id` then `query-docs`. | yes for external dependencies |

Example `~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.com/mcp",
      "enabled": true
    }
  }
}
```

### Models

Both agents pin their model. The `github-copilot` provider must be
authenticated (`opencode auth login`):

| Agent | Model |
|---|---|
| thot | `github-copilot/claude-opus-5` |
| imhotep | `github-copilot/gpt-5.6-terra` |

Different provider? Change `model:` in `agent/thot.md` and `agent/imhotep.md`.

### CLI tools

thot allows `rg`, `fd`, `find`, `head`, `tail`, `sed -n`, `wc`, and read-only
`git` commands without a prompt. `cat` is intentionally not allowlisted to avoid
large accidental dumps.

## Installation

```bash
./install.sh
```

Creates symlinks:

| Repo | Target |
|---|---|
| `agent/` | `~/.config/opencode/agent` |
| `command/start-work.md` | `~/.config/opencode/command(s)/start-work.md` |

Idempotent. Aborts if a target exists and is not a matching symlink.

Restart opencode afterwards; config is loaded at startup.

## Workflow

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

`claude-opus-5`

- Plans only; never implements.
- Hard-enforced edit scope: `docs/plans/**` only.
- Explores before asking and cites findings with `file:line`.
- Uses Context7 for external API/library details.
- Asks only owner decisions: irreversible/security-critical choices, public API
  or config, data/schema, new dependencies, packaging, migrations.
- Requires an approval brief before writing the plan and review context.
- Records every planning decision and assumption separately for future reviews.
- Plan mode is sticky: "do X" means "plan X".

## imhotep — Worker

`gpt-5.6-terra`

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
- No commits and no commit suggestions. Commit/history-changing commands are
  blocked via `permission.bash`.
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
docs/plans/<slug>.md
docs/plans/<slug>.review-context.md
```

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
| `permission.edit`, `permission.bash` | hard when the matching agent is active |
| `question` blocks the turn | hard |
| `model`, `temperature` | hard |
| caveman style, step gate, fresh-session flow, scope guard, final-verification flow | soft model instruction |
| `## Execution rules` in the plan | soft, but survives compaction |

The commit lock is real. The rest is discipline, not a guarantee, so the core
rules live both in the agent prompt and every plan.

## Deliberately omitted

Team mode, dual review, separate plan review agents, SHA256 round contracts,
draft state, scaffold script, category routing, and lifecycle hooks. With two
sequential agents they mostly cost prompt budget.
