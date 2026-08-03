# agents

Two opencode agents: **thot** plans, **imhotep** builds.

Modeled on the planner/worker split of
[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent), but without
subagent orchestration, team mode, and dual review.

## Prerequisites

Both agents assume the following is already installed in opencode. Nothing
here is bundled by `install.sh`.

### Skills

| Skill | Used by | Why | Required |
|---|---|---|---|
| `caveman` | imhotep | Mandatory first action of every session and of `/start-work`. Every user-facing output is caveman-terse. | yes |
| `caveman-commit` | imhotep | Generates the commit message in the review gate's commit suggestion. | recommended — without it imhotep writes the Conventional Commit subject itself |

Install them under `~/.config/opencode/skills/<name>/SKILL.md`.

### MCP servers

| Server | Used by | Why | Required |
|---|---|---|---|
| `context7` | thot | Library, framework, SDK, and CLI research during exploration: `resolve-library-id` then `query-docs`. Rule: never answer from memory. | yes for external dependencies, otherwise optional |

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
| imhotep | `github-copilot/gpt-5.6-sol` |

Different provider? Change the `model:` field in `agent/thot.md` and
`agent/imhotep.md`.

### CLI tools

thot's bash allowlist grants `rg` and `fd` without a prompt. Both are optional;
`grep` is a sufficient fallback. Missing tools do not break anything, but
exploration gets slower because every alternative command triggers an `ask`
prompt.

The built-in `explore` subagent is used via `task(subagent_type="explore")` —
part of opencode, no installation required.

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

**Restart opencode afterwards** — the configuration is only loaded at startup.

## Workflow

```
  Agent: thot                      Agent: imhotep
  ───────────                      ──────────────
  explores                         loads caveman
  asks (owner decisions only)      reads the plan
  waits for your OK                builds todo 1
  writes .plans/<slug>.md    ───>  Gate: review
                                   builds todo 2
                                   Gate: review
                                   ...
                                   Final verification
```

The plan file is the only interface. No shared context. That is why the plan
must be **decision-complete**: imhotep makes no decisions.

```
switch agent to thot, describe the task
  ...
switch agent to imhotep (tab or ctrl+x, then a)
/start-work <slug>
```

## thot — Planner

`claude-opus-5`

- Explores first, asks later. Evidence with `file:line`.
- **Two filters** before every question: answerable through exploration → find
  out yourself. Answerable through a defensible default → default and log it.
  What remains are owner decisions: irreversible, security-critical, data
  schema, public API, new dependency.
- **Approval gate.** Approval only authorizes writing the plan, never
  execution.
- Plan mode is sticky: "do X" means "plan X".

With thot active, hard-enforced `permission.edit` allows `.plans/**`
exclusively; under that condition, thot *cannot* change production code.

## imhotep — Worker

`gpt-5.6-sol`

- **caveman skill** as the first mandatory action of every session.
- **Review gate after every todo.** Implement → QA → stop → `question` with
  diff, QA evidence, commit suggestion, and the options
  continue/rework/stop. Only after "continue" is it checked off.
- **No commits.** Blocked via `permission.bash`: `commit`, `push`, `merge`,
  `rebase`, `reset`, `tag`, `revert`, `cherry-pick`, `gh pr create|merge`.
  Allowed: `status`, `diff`, `add`, `log`, `stash`.
- Escalates instead of improvising: plan wrong → stop, back to thot.

## Language

Prompts and plan files use English for stronger instruction compliance, lower
token usage, and later compaction. User-facing responses follow the user's
language. Review gate triggers accept both `weiter` and `continue`.

## Switching agents

The `agent:` field in command frontmatter does not switch a `primary` agent;
the command prompt runs under the currently active agent.

| Method | Action |
|---|---|
| Cycle | Press `tab` (`agent_cycle`) |
| Select | Press `ctrl+x`, then `a` (`agent_list`) |
| New session | Run `opencode --agent imhotep` |

Without switching, `/start-work` runs with thot's permissions. Identity guards
in imhotep and the command abort before plan execution.

## Plan format

`.plans/<slug>.md`

```
## TL;DR
## Execution rules      <- verbatim in every plan, anchor after compaction
## Scope                In / Out / Must-NOT-Have
## Findings             facts with file:line
## Decisions            decision + rationale + rejected alternative
## Todos                - [ ] N.  at column 0
## Final verification   - [ ] F<n>.  at column 0
## Success criteria
```

Task lines sit at column 0 and follow exactly `- [ ] N.` or `- [ ] F<n>.`
— imhotep checks off precisely those lines.

Target range 5–8 todos. Implementation and test are one todo. The worker stops
after every todo, so cut review-sized units instead of micro steps.

## What is hard-enforced

| Mechanism | Enforcement |
|---|---|
| `permission.edit`, `permission.bash` | **hard when the matching agent is active** — harness blocks the tool call |
| `question` blocks the turn | hard |
| `model`, `temperature` | hard |
| caveman requirement, step gate, scope guard | soft — model self-binding |
| `## Execution rules` in the plan | soft, but survives compaction |

The commit lock is real. The rest is discipline, not a guarantee — that is why
the rules are stated twice: in the prompt and in every plan file.

## Deliberately omitted

Team mode, dual review (`momus` + `oracle`), `metis` gap analysis,
SHA256 round contracts, draft state, scaffold script, category routing,
lifecycle hooks. Those are omo's answers to multi-agent parallelism — with two
sequential agents they only cost prompt budget.

Known trade-off: no second pair of eyes on the plan. Planning mistakes only
surface at the step gate, when the code is already written.
