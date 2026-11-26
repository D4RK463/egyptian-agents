# egyptian-agents

Thot plans, Horus reviews the plan, and Imhotep builds — in opencode or Claude
Code. Seshat builds the same plan with you: she leaves selected backend parts to
you as learning tasks and coaches you through them.

Modeled on the planner/worker split of
[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent), but without
subagent orchestration or team mode. The review step is a single optional
plan-review gate, not oh-my-openagent's dual review.

## Prerequisites

All agents assume these optional/required pieces already exist in
opencode or Claude Code. `install.sh` only links files from this repo and the
installed opencode `caveman` skill.

### opencode version

The opencode agents use the **v1 config format** (`mode`, `permission:` map)
and only work with opencode v1 for now. Current opencode docs describe a v2
format (`permissions` rule list, `shell`, `subagent`); compatibility with v2 is
untested and tracked as a separate task. Claude Code is unaffected.

### Skills

| Skill | Used by | Why | Required |
|---|---|---|---|
| `caveman` | imhotep, seshat | Loaded before plan execution. Gates, errors, and final reports stay terse. Seshat's learning messages do not use it. | yes |

Install opencode skills under `~/.agents/skills/<name>/SKILL.md`. Claude Code
loads skills from `~/.claude/skills/<name>/SKILL.md`; when
`~/.agents/skills/caveman` exists, `install.sh` symlinks it into
`~/.claude/skills/caveman`.

### MCP servers

| Server | Used by | Why | Required |
|---|---|---|---|
| `context7` | thot, horus | Current docs for libraries/frameworks/SDKs/CLIs: `context7_resolve-library-id` then `context7_query-docs`. | yes for external dependencies |

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

All agents pin their model. The `github-copilot` provider must be
authenticated (`opencode auth login`):

| Runtime | Agent | Model |
|---|---|---|
| opencode | thot | `github-copilot/claude-opus-5` |
| opencode | horus | `github-copilot/claude-opus-5` |
| opencode | imhotep | `github-copilot/gpt-5.6-terra` |
| Claude Code | thot | `opus` |
| Claude Code | horus | `opus` |
| Claude Code | imhotep | `sonnet` |
| opencode | seshat | `github-copilot/claude-opus-5` |
| Claude Code | seshat | `opus` |

Horus runs on the same tier as thot, not imhotep: a reviewer weaker than the
plan's author is more likely to miss the fit mismatches and AK gaps it exists
to catch, and rubber-stamping defeats the gate. Different provider? Change
`model:` in the relevant agent file. Claude Code variants run on the Anthropic
subscription; opencode agents remain on `github-copilot`. Seshat runs on the
top tier because hints that point at a problem without giving the answer away
are harder than executing a todo; downgrade if cost becomes an issue.

### CLI tools

thot and horus share the same allowlist: `rg`, `fd`, `find`, `head`, `tail`,
`sed -n`, `wc`, and read-only `git` commands. `rg` may be absent; use `git
grep` or `grep` portably.
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
| `command/review-plan.md` | `~/.config/opencode/command(s)/review-plan.md` |
| `claude/agents/thot.md` | `~/.claude/agents/thot.md` |
| `claude/agents/horus.md` | `~/.claude/agents/horus.md` |
| `claude/agents/imhotep.md` | `~/.claude/agents/imhotep.md` |
| `claude/agents/research.md` | `~/.claude/agents/research.md` |
| `claude/agents/seshat.md` | `~/.claude/agents/seshat.md` |
| `command/start-learning.md` | `~/.config/opencode/command(s)/start-learning.md` |
| `claude/commands/start-learning.md` | `~/.claude/commands/start-learning.md` |
| `claude/commands/start-work.md` | `~/.claude/commands/start-work.md` |
| `claude/commands/review-plan.md` | `~/.claude/commands/review-plan.md` |
| `~/.agents/skills/caveman` | `~/.claude/skills/caveman` |

Claude Code step is skipped when `~/.claude` is absent. Paste
`claude/settings.example.json` into `~/.claude/settings.json` manually;
`install.sh` never writes that file.
Start Claude Code planning with `claude --agent thot`, review with
`claude --agent horus`, or execution with `claude --agent imhotep`; use
`/review-plan <slug>` to review a plan and `/start-work <slug>` to resume it.

It also copies `seshat/logbook.template.md` to
`~/.config/seshat/logbook.md` when that file is missing (a copy, not a symlink,
so personal entries never land in this repo) and creates
`~/.config/seshat/solutions/`.

Idempotent. Aborts if a target exists and is not a matching symlink.

Restart opencode afterwards; config is loaded at startup.

## Workflow

The plan pair plus the horus review verdict in `docs/plans/` is the only
interface. Cross-tool execution works: plan with `claude --agent thot`, review
with `opencode --agent horus`, then execute with `opencode --agent imhotep` —
any combination of runtimes works because the files, not the chat session, are
the contract. A Claude-Code-only round trip also works: plan with
`claude --agent thot`, review with `claude --agent horus`, then execute with
`claude --agent imhotep` and `/start-work <slug>`.

Horus review is optional: imhotep executes a plan without a horus review file
at all. If a review file exists and carries `Verdict: CHANGES_REQUESTED`,
imhotep refuses to run until thot amends the plan and, if you want another
review, horus reviews again.

Horus review is optional: skip straight from thot to imhotep by running
`/start-work <slug>` without `/review-plan <slug>` first.

```text
Agent: thot                 Agent: horus (optional)     Agent: imhotep
───────────                 ────────────                ──────────────
explores                    reads plan +                loads caveman
asks owner decisions only    review context              reads the plan
waits for your OK           asks for the user            checks horus verdict
writes plan +                 story's AK, if any         builds first open todo
  review context             judges implementation        Gate: review
                              fit + AK + gaps             checkpoint + stop
                             writes horus-review    ───>  new session +
                               file with verdict            `/start-work <slug>`
                                                          builds next open todo
                                                            Gate: review
                                                          checkpoint + stop
                                                          ...
CHANGES_REQUESTED ──> back to thot, amends plan,          restart after all
  deletes horus-review file, horus reviews again          N. done ────────────>
                                                          final verification
                                                            without gates
                                                          final report
```

Use opencode:

```text
switch agent to thot, describe the task
...
switch agent to horus (tab or ctrl+x, then a)
/review-plan <slug>
...
switch agent to imhotep (tab or ctrl+x, then a)
/start-work <slug>
```

Use Claude Code: agents are selected when starting a session, not switched in
an existing session.

```bash
claude --agent thot
# plan the task, then start a new session:
claude --agent horus
# run: /review-plan <slug>
# on APPROVED, start a new session:
claude --agent imhotep
# then run: /start-work <slug>
```

The plan, its review context, and the horus review verdict are the only
interface and state store. Sessions are disposable. That is why plans must be
decision-complete, and later-needed facts/decisions are persisted back into
those files.

## thot — Planner

- Plans only; never implements.
- Hard-enforced edit scope: `docs/plans/**` only.
- Explores before asking and cites findings with `file:line`.
- Uses Context7 for external API/library details; delegates any other
  external fact blocking an owner decision to the `research` subagent, which
  returns a cited, condensed answer instead of raw fetched pages.
- Asks only owner decisions: irreversible/security-critical choices, public API
  or config, data/schema, new dependencies, packaging, migrations.
- Requires an approval brief before writing the plan and review context.
- Records every planning decision and assumption separately for future reviews.
- Plan mode is sticky: "do X" means "plan X".
- Final report mentions horus review as an optional next step; `/start-work`
  works directly without it.

## horus — Reviewer

- Reviews only; never implements, and never edits the plan or review context.
- Hard-enforced edit scope: `docs/plans/**` only, and only its own
  `<slug>-plan.horus-review.md`.
- Always asks for the user story's acceptance criteria (AK) when the initial
  prompt did not already include them; a plan without a user story is a valid,
  fully reviewable outcome.
- Reads thot's review context and does not propose reversing a recorded
  decision without new, concrete codebase evidence.
- Explores the current codebase like thot to judge implementation fit, citing
  every mismatch as `file:line`; delegates external `assumption-to-verify`
  entries beyond library/API surface to the `research` subagent.
- Checks AK coverage per criterion against todo `Acceptance`/`QA`, not against
  prose; an uncovered criterion is a gap even if mentioned in `TL;DR`.
- Also searches for gaps thot and the requester could plausibly have missed:
  unaccounted callers/usages of touched code, tests the plan would break,
  missing migrations/config for a changed contract, and failure/error paths
  no todo mentions. Every gap needs a concrete `file:line` anchor; a
  speculative "nice to have" is not a finding.
- Writes exactly one verdict, `APPROVED` or `CHANGES_REQUESTED`, to
  `docs/plans/<slug>-plan.horus-review.md`.
- Runs in its own session/context, same as thot and imhotep.

## imhotep — Worker

- Verifies it is the active agent before reading or writing.
- Horus review is optional: runs without a `docs/plans/<slug>-plan.horus-review.md`
  file. If one exists and carries `Verdict: CHANGES_REQUESTED`, it stops
  before it reads plan state until thot amends the plan.
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

## seshat — Teaching worker

Executes the same plans as imhotep, one todo per session, with the same gate,
checkpoint, final verification, no-commit rule, and scope guard. Start it with
`claude --agent seshat` / `opencode --agent seshat` and `/start-learning <slug>`.

A todo with a `Learn:` field (written by thot) contains a part you implement:

1. Seshat builds everything outside `You:`.
2. She creates a compiling skeleton for `You:`: signatures, a not-implemented
   body marked `seshat`, and numbered `// TODO(seshat) <n>:` comments.
3. `Check: tests`: she writes the tests first; they are red until your code is
   right. `Check: solution` (config, migrations, build, infrastructure): she
   writes a hidden solution under `~/.config/seshat/solutions/`, outside the
   repo, and compares against it. A different correct solution passes.
4. The todo becomes `- [~]` with a `Learn state:` line, so a new session can
   resume it. You implement, then write `check`.
5. Check loop, one problem at a time:

   | You write | You get |
   |---|---|
   | `check` / `prüfen` | stage 1: location only |
   | `genauer` / `more` | stage 2: location and what is wrong, no code |
   | `warum` / `why` | stage 3: why, with the codebase's rule and reference |
   | `zeig lösung` / `show solution` | the solution diff for the current problem |
   | `mach du` / `you do it` | seshat finishes your part |

6. Passed: normal gate, checkpoint, logbook update.

Skeleton comment detail depends on your level for that pattern in this project:
`new` = what to do plus a reference `file:line`; `seen` = what to do only;
`confident` = the goal only. Learning messages use fixed templates in plain
language (next action first, at most 5 items, no preamble or recap; adapted
from [i-have-adhd](https://github.com/ayghri/i-have-adhd), MIT); gates and
checkpoints stay caveman-terse.

### Learning logbook

`~/.config/seshat/logbook.md` is a private, global record across all projects:
per backend pattern (e.g. `rest-endpoint`, `flyway-migration`) how often you
implemented it yourself, when you last did, and a reference per project. Its
`## Rules` header is the single source for levels: Done 0 = `new`, 1–2 =
`seen`, ≥3 or self-reported = `confident`; 90 days without practice drops one
level; a pattern you have not done in the current project counts as `new` there.

- **thot** reads it, asks which unknown patterns you already know (multi-select)
  and appends those answers, then plans learning todos: budget
  `max(1, ceil(implementation todos / 4))`, priority `new` -> decayed -> `seen`,
  only where a reference exists in the repo or earlier in the plan. Opt out
  with `keine Lernaufgaben` / `no learning`.
- **seshat** counts a pattern only when you passed without `zeig lösung` /
  `mach du`, and records patterns she built as references for later plans.
- **horus** checks learning todos (reference exists, scope excludes tests and
  frontend, check mode fits, budget) but never reads the logbook.
- **imhotep** ignores `Learn:` and builds those todos completely, so any plan
  can still run at full speed.

The logbook never enters plan files, review contexts, or the repository: plans
carry only pattern ids, `You:` scope, reference, and check mode. Tests and
frontend are never learning scope.

## Claude Code variant

`claude/agents/thot.md`, `claude/agents/horus.md`, and
`claude/agents/imhotep.md` are independently maintained Claude Code prompts.
Edit the opencode and Claude Code file of each agent together on prompt
changes; no generator or shared body keeps either pair synchronized.
`claude/agents/research.md` / `agent/research.md` are the same pair for the
`research` subagent, wired into both thot and horus.
`claude/agents/seshat.md` / `agent/seshat.md` are the pair for seshat; her
deltas mirror imhotep's, and the opencode variant has no repository-records
section, like opencode imhotep.

`claude/commands/start-work.md` resumes plans with `/start-work <slug>`, and
`claude/commands/review-plan.md` runs the horus gate with
`/review-plan <slug>`. Both use `$ARGUMENTS`; opencode's `command/start-work.md`
and `command/review-plan.md` use 1-based `$1`, while Claude Code `$1` means the
second argument.

Thot prompt deltas: Claude Code uses `Agent` and `Explore` instead of
`task(subagent_type=...)`; it has no `scout`; external facts beyond
library/API surface go to the `research` subagent via
`Agent(Explore, research)` instead of `task(subagent_type="research")`; it
uses `mcp__context7__*` tool names and `AskUserQuestion` instead of
`question`; its frontmatter has no `mode` or `temperature`.

Horus prompt deltas mirror Thot's: `Agent`/`Explore` instead of
`task(subagent_type=...)`, external `assumption-to-verify` facts go to
`research` via `Agent(Explore, research)`, `mcp__context7__*` tool names,
`AskUserQuestion` instead of `question`, `claude --agent horus` as its
identity guard, no `mode` or `temperature` in frontmatter.

Imhotep prompt deltas: `AskUserQuestion` replaces `question`; `Skill` loads
`caveman`; `claude --agent imhotep` is its identity guard; omitting `Agent`
prevents subagents; frontmatter has no `mode`, `temperature`, or `permission`;
`permissionMode: acceptEdits` accepts edits; Bash accepts a per-call `timeout`
and backgrounds commands that exceed it.

The `## Execution rules` block in generated plans stays opencode-flavoured on
purpose. Either Imhotep variant maps its tool names when executing it.

## Language

Prompts and plan files use English for stronger instruction compliance and lower
token use. User-facing chat responses follow the user's latest language; only
fixed markers like `THOT: PLAN MODE`, code, commands, paths, and plan files stay
English. Review gate triggers accept both German and English continuation words.

## Switching agents

### opencode

The `agent:` field in command frontmatter does not switch a `primary` agent;
the command prompt runs under the currently active agent.

| Method | Action |
|---|---|
| Cycle | Press `tab` (`agent_cycle`) |
| Select | Press `ctrl+x`, then `a` (`agent_list`) |
| New session | Run `opencode --agent horus` or `opencode --agent imhotep` |

Without switching, `/review-plan` or `/start-work` can run with the wrong
agent's permissions. Identity guards in horus, imhotep, and both commands
abort before review or execution.

### Claude Code

Start a separate session with the required agent: `claude --agent thot` for
planning, `claude --agent horus` for review, or `claude --agent imhotep` /
`claude --agent seshat` for execution. Claude Code's `--agent` option applies to that session; do not use
`/review-plan` or `/start-work` from a Thot session. Horus's and imhotep's
identity guards abort before review or execution if they are not the active
agent.

## Plan, review-context, and horus-review format

Every new plan creates this pair:

```text
docs/plans/<slug>-plan.md
docs/plans/<slug>-plan.review-context.md
```

Horus adds a third file once it has reviewed the plan:

```text
docs/plans/<slug>-plan.horus-review.md
```

`<slug>` is lowercase kebab-case and excludes the suffix; `/review-plan <slug>`
and `/start-work <slug>` resolve the corresponding `<slug>-plan.md` file (and,
for imhotep, its `-plan.horus-review.md`). Every plan filename therefore ends
in `-plan.md`.

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
validity. Horus, like any reviewer, must read it before proposing changes and
may reverse a recorded decision only with new, concrete evidence. Older plans
may not have a review-context file.

The horus-review file carries exactly one `Verdict:` line, `APPROVED` or
`CHANGES_REQUESTED`, plus the fit mismatches, AK gaps, and overlooked gaps it
found. It is disposable state, not a decision record: thot deletes it on every
amendment, and horus rewrites it from scratch on every review.

Learning todos add a `Learn:` block (pattern ids, `You:`, `Reference:`,
`Check: tests | solution`). While seshat waits for you, a todo is `- [~] N.`
with a `Learn state:` line; both count as open, and the checkpoint removes
them.

Task lines must be exactly `- [ ] N.` or `- [ ] F<n>.` at column 0. Target 5–8
implementation todos. Implementation and test are one todo.

Current execution rule summary:

1. Load `caveman` first.
2. No commits or history changes.
3. Horus review is optional: run without a horus-review file; refuse only on
   `Verdict: CHANGES_REQUESTED`.
4. Each session executes only the first unchecked implementation todo `N.`.
5. Gate after that todo, then checkpoint and stop on approval.
6. Final verification `F<n>` runs without gates unless it fails.
7. `Must-NOT-Have` is binding.
8. Plan wrong or reality differs: stop and return to thot.

## What is hard-enforced

| Mechanism | Enforcement |
|---|---|
| opencode `permission.edit`, `permission.bash` | hard when matching agent is active |
| Claude Code edit scope | soft: `Edit(docs/plans/**)` is allowed; all other edits are ask-by-default, not denied |
| opencode `question` blocks the turn | hard |
| Claude Code `AskUserQuestion` blocks the turn | unverified; text brief plus end-of-turn remains fallback |
| model, temperature | hard where agent runtime supports them |
| Claude Code commit lock | soft: prompt-only; agent frontmatter cannot carry Bash rules, and settings rules apply to every session |
| Horus gate (optional; imhotep refuses only on `Verdict: CHANGES_REQUESTED`) | soft: prompt-only file check, same enforcement class as the identity guards |
| caveman style, step gate, fresh-session flow, scope guard, final-verification flow | soft model instruction |
| `## Execution rules` in the plan | soft, but survives compaction |
| Logbook privacy (never copied into plans or the repo) | soft: prompt-only; `install.sh` copies instead of symlinking |
| thot logbook write in opencode | `edit` allows `~/.config/seshat/logbook.md`; whether v1 matches `~` paths is untested |
| Claude Code logbook access | `Read`/`Edit(~/.config/seshat/**)` in `settings.example.json` applies to every session, not only thot and seshat |

OpenCode commit lock is real. Claude Code commit lock is prompt-only. Other core
rules are discipline, so they live both in the agent prompt and every plan.

## Deliberately omitted

Team mode, dual review (two independent reviewers, or reviewer + counter-review
of the reviewer), SHA256 round contracts, draft state, scaffold script,
category routing, and lifecycle hooks. Horus is a single optional gate, not a
second parallel reviewer; staleness after an amendment is handled by thot
deleting the horus-review file, not by hashing plan content. With three
sequential agents these would mostly cost prompt budget.
