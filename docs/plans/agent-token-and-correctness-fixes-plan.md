# agent-token-and-correctness-fixes — Work Plan

## TL;DR

**What you get:** thot stops asserting framework behaviour it has not traced, stops writing RED
conditions it never ran, and gains a mandatory entry-path matrix for surface-wide invariants.
imhotep gains an environment preflight, an `env` vs `plan` blocker classification, a hard
`permission.task` deny, and stages its own output so `git grep` and `git status` become usable
oracles. Plan files stop growing with every repair and shed completed-todo bulk.

**Why this approach:** Every fix targets a measured cause. 22 of 45 imhotep sessions on the public
catalog work ended in `Blocked:` ($19.99); 5 of 9 thot sessions were pure repair ($8.19); two
external review rounds found defects that no mechanism checked. 94% of imhotep's tokens were re-read
context, 65% of it the plan file. Prompt lines are near-free at 20.6 turns per session; a failed
session costs $0.91.

**What it does NOT do:** No change to plan paths or filenames, no commit permission, no `Refs:`
lines or selective plan reading, no structural rewrite of either agent, no retrofit of existing
plans, no change to `opencode.jsonc`, no removal of the agent identity guard.

**Effort:** Medium — 6 implementation todos, 4 final verification tasks, 5 files.

**Risk:** Low-medium. This plan edits the prompts of the agents executing it. opencode loads agent
configuration at startup, so no todo can verify its own result behaviourally. All acceptance
criteria are static; behaviour is proven once in F4 after a restart.

## Execution rules

1. First load `skill(name="caveman")`; user output stays caveman-terse.
2. No commits or git history changes.
3. On start, read this whole plan, inspect current worktree, skip checked todos, and execute only the first unchecked implementation todo `N.`.
4. For that todo: implement, run listed QA, stop, call `question`, and wait.
5. After explicit `weiter` / `continue` / `ok` / `go`: persist later-needed facts/decisions in this plan, check off only that todo, remind the user to start a NEW session for token savings, print the next `/start-work` command for this plan, then stop.
6. When all implementation todos are checked at session start, run final verification tasks `F<n>` without gates. Stop only on failure; otherwise report once.
7. `Must-NOT-Have` is binding; extra ideas go to `## Findings`, not code.
8. If the plan is wrong or reality differs, stop and hand back to thot.
9. At checkpoint, stage the todo's own files with `git add -- <Files of that todo>`. This plan
   introduces that rule and applies it to itself. Never run `git stash` while staged plan work
   exists; it would carry the staged work away.
10. `~/.config/opencode/opencode.json` is machine-local and outside this repository. Todo 1 edits
    it; no other todo may. It is invisible to every `git` command run here.
11. Agent configuration is loaded at opencode startup. Editing `agent/imhotep.md` does not change
    the running session. Never assert an acceptance criterion that requires an edited prompt to be
    active in the same session.

## Branch

Work happens on the current branch of `IdeaProjects/personal/agents`. `.idea/misc.xml`,
`.idea/modules.xml`, `.idea/vcs.xml` and `agents.iml` are untracked IntelliJ files that predate this
plan. Leave them; they are not scope violations.

## Scope

**In:**

- `agent/thot.md` — evidence rules, six quality checks, two template sections, amendment policy
- `agent/imhotep.md` — preflight, blocker classification, bash timeout, `permission.task`, staging,
  per-todo lint (conditional on the project defining a lint entry point, D13), completed-todo
  shrinking, on-demand review context
- `command/start-work.md` — review context on demand instead of always
- `README.md` — correct the prerequisites that do not match reality
- `~/.config/opencode/opencode.json` — register the context7 MCP server, deny it globally

**Out:**

- Existing plans in this repository or in `bss-modulith`
- `install.sh`
- Model pins, temperatures, `steps` budgets

**Must-NOT-Have:**

- No change to `docs/plans/<slug>-plan.md` naming or location
- No commit permission for imhotep, and no weakening of the blocked git commands
- No `Refs:` lines and no selective plan reading
- No removal or weakening of the imhotep identity guard (`agent/imhotep.md:25-30`,
  `command/start-work.md:8-10`), introduced deliberately by `docs/plans/agent-switch-guard-plan.md`
- No use of the deprecated `tools` config field
- No edit to `~/.config/opencode/opencode.jsonc`
- No new MCP server besides context7

## Findings

**Installation drift — the README describes an environment that does not exist**

- `README.md:22-42` — declares `context7` a prerequisite, `required: yes for external dependencies`,
  and prints the exact `opencode.json` block to install.
- `~/.config/opencode/opencode.json` — 51 bytes, contains only `$schema`. No `mcp` key. The server
  was never installed.
- opencode session store, `bss-modulith`, since 2026-08-28: zero tool calls matching `%context7%`
  across 62 sessions. thot rule 2 (`agent/thot.md:58-59`) was unexecutable, not ignored.
- `README.md:20` — "Install skills under `~/.config/opencode/skills/<name>/SKILL.md`". The actual
  location is `~/.agents/skills/` (14 skills plus `.skill-lock.json`); `~/.config/opencode/skills/`
  does not exist. Caused `Blocked: required caveman skill is unavailable`.
- `README.md:57` — thot allowlists `rg`. `rg` is not installed and Hermit does not provide it.
  Caused two blockers.
- `README.md:26` — names the tools `resolve-library-id` and `query-docs`. MCP tools are registered
  with the server name as prefix, so the real names are `context7_resolve-library-id` and
  `context7_query-docs`. The rule would still have missed after installation.

**Framework facts were asserted from class-name searches**

- Seven blockers originated in `## Findings` claims about Spring or Jackson runtime behaviour. The
  largest: the plan claimed no MVC code path fills `ProblemDetail.instance`, having searched
  `ResponseEntityExceptionHandler`. It is set in `RequestResponseBodyMethodProcessor:203`, one
  handler further along. All seven were dependency source behaviour, not API documentation.
- opencode docs `/docs/agents#use-scout`: `scout` is a read-only subagent that clones dependency
  repositories into opencode's cache and inspects library source. thot already has `task: allow`
  (`agent/thot.md:27`).

**Verification was constructed without being run**

- Six blockers were unreachable or tautological RED conditions: a `compileKotlin` RED against a
  positional constructor argument; a unit test that serialized `ProblemDetail` directly and never
  entered MVC; a guard grepping the bare verb `.project(` with about 30 foreign hits; `git grep`
  against untracked files; a repo-wide `sendError` search matching legitimate private paths.
- `agent/thot.md:92-93` requires a "concrete RED condition" but not that it was executed.

**Surface invariants were implemented per enumerated case**

- Both external review rounds report the same shape: an invariant declared for a whole surface,
  implemented only for the paths someone thought of. The catalog plan cited DEC-GLOB-097 49 times
  and still omitted the Spring Security ERROR dispatch, the DispatcherServlet
  `NoResourceFoundException` path, and the `categoryId` filter.
- Three of those defects stayed green because MockMvc performs no ERROR dispatch and does not run
  the return-value handlers. `agent/thot.md:92-93` mentions real infrastructure but gives no
  criterion for when a mock cannot prove a risk.
- Neither resource cost nor "the recovery path must not itself throw" appears anywhere in
  `agent/thot.md:81-99`. Both were review findings.

**Token structure — where the money actually is**

- imhotep, 45 sessions: 42.7M `cache_read`, 2.1M fresh input, 0.25M output; average 20.6 turns and
  949k `cache_read` per session. 94% of cost is re-read context.
- The catalog plan is about 30 000 tokens, read whole per Execution rule 3 and resident in every
  turn: 30k x 20.6 x 24 sessions is roughly 14.8M tokens for one file.
- Section sizes of that file: `## Todos` 14 230 tokens with 9 of 10 todos checked; `## Findings`
  7 709; `## Decisions` 3 983.
- The same file contains 21 amendment blocks. `agent/thot.md:220-225` does not require deleting a
  refuted finding, so every blocker made the plan larger and every later session more expensive.
- `agent/imhotep.md:50-52` and `command/start-work.md:6` read the review context every session:
  9 307 extra tokens for this plan family.
- 22 of 45 imhotep sessions ended with a `Blocked:` report: $19.99. thot repair sessions: $8.19.
  Total failure share $28.18 of $78.17, or 36%.

**Configuration mechanics**

- opencode docs `/docs/agents#tools-deprecated`: `tools` is deprecated; use `permission`. Permission
  keys are matched as wildcard patterns against the underlying tool name, so `"context7_*"` works
  for MCP tools.
- opencode docs `/docs/agents#task-permissions`: `permission.task` accepts globs, and `deny` removes
  the subagent from the Task tool description entirely.
- imhotep delegated todo 5 of the catalog plan to the `general` subagent: 2.8M tokens, 12
  `apply_patch` calls, without the plan, the `Must-NOT-Have`, or the commit ban.
- `agent/imhotep.md:146` currently allows `git stash`.
- `install.sh:38,49` links only `agent/` and `command/start-work.md`. `opencode.json` is
  machine-local and never touched by the installer.
- `~/.config/opencode/` contains both `opencode.json` and `opencode.jsonc`, each holding only
  `$schema`. Precedence is unclear. Reported, not changed — see D9.

**The per-todo lint rule assumed a lint entry point that this repository does not have**

- `agent/imhotep.md:159` (after Todo 5) reads "Run project lint entry point after every
  implementation todo" without a condition, and `agent/imhotep.md:48` lists it as a preflight
  prerequisite whose absence is a `Class: env` blocker (`agent/imhotep.md:155`).
- This repository is prompt and markdown only: no `package.json`, no markdownlint or prettier
  configuration, no CI workflow, no lint target in `install.sh`. `markdownlint` and `prettier` are
  not on `PATH`; `npm`, `node` and `shellcheck` are.
- The plan's own final verification defines no lint task: F2 is a byte budget, F3 is scope fidelity.
- Consequence, observed: executing Todo 6 under the already-restarted, Todo-5-edited imhotep prompt
  produced `Blocked: todo 6 missing project lint entry point`. The rule is unsatisfiable in any
  project without a lint entry point, which includes this one. See D13.

**Self-reference**

- opencode loads agent configuration at startup. Todos 4, 5 and 6 edit prompts that the executing
  imhotep is running from; those edits take effect only after a restart. Acceptance must be static.
  `install.sh` closes with "WICHTIG: opencode neu starten. Die Konfiguration wird nur beim Start
  geladen."

**Retracted assumption**

- An earlier draft proposed deleting `agent/imhotep.md:25-30` (`## First action`) on the assumption
  that the `agent: imhotep` frontmatter of `/start-work` switches the agent. `README.md`, section
  "Switching agents", states the opposite, and `docs/plans/agent-switch-guard-plan.md` introduced
  the guard deliberately across four checked todos. Session `ses_fa7f214ab` ran the `/start-work`
  prompt under the `build` agent. The guard stays. See D11.

## Surface invariants

The surface of this plan is the pair of agent prompts plus the two files that drive them. Two
invariants are stated globally, so every entry path must be accounted for.

| Entry path | I1: no deprecated config field | I2: identity guard intact |
|---|---|---|
| `~/.config/opencode/opencode.json` | Todo 1 writes `permission`, never `tools`; F3(e) asserts `"tools"` absent | not applicable, no agent prompt |
| `agent/thot.md` frontmatter | Todo 2 adds `"context7_*": allow` inside the existing `permission` block | thot has no guard; unaffected |
| `agent/imhotep.md` frontmatter | Todo 5 adds `permission.task`, not `tools` | frontmatter untouched apart from `task`; F3(d) asserts the guard line survives |
| `agent/imhotep.md` body | no config field in the body | Todo 5 explicitly leaves `## First action` byte-identical; Todo 6 edits only the review-context, checkpoint and lint sentences |
| `command/start-work.md` | no config field beyond `agent:` frontmatter, unchanged | Todo 6 touches only the review-context sentence; the guard paragraph at `:8-10` is out of scope |
| `README.md` | Todo 5 rewrites the MCP example to the `permission` form | Todo 5 does not touch the "Switching agents" section |

## Decisions

- **D1: context7 was never installed; the rule was not ignored** — see `review-context`.
- **D2: use `permission`, never the deprecated `tools` field** — see `review-context`.
- **D3: `scout` for dependency source, context7 for API surface** — see `review-context`.
- **D4: `permission.task: deny` instead of a prompt rule** — see `review-context`.
- **D5: stage per todo, keep the commit ban** — see `review-context`.
- **D6: shrinking a checked todo keeps `Files:` and `Acceptance:`** — see `review-context`.
- **D7: no `Refs:` lines, no selective plan reading** — see `review-context`.
- **D8: plan paths and filenames stay unchanged** — see `review-context`.
- **D9: the `opencode.jsonc` duplicate is reported, not changed** — see `review-context`.
- **D10: this plan verifies statically; behaviour is proven once in F4** — see `review-context`.
- **D11: the imhotep identity guard stays** — see `review-context`.
- **D12: prompt tokens are near-free, plan tokens are not** — see `review-context`.
- **D13: the per-todo lint rule is conditional on the project defining one** — see `review-context`.
- **D14: F1's staged file list includes the plan files themselves** — see `review-context`.

## Names

Identifiers introduced or changed by this plan, so no later todo invents a variant.

| Kind | Name | Introduced in |
|---|---|---|
| MCP server | `context7` | Todo 1 |
| Permission pattern | `context7_*` | Todo 1, Todo 2 |
| Permission key | `task` | Todo 5 |
| thot section | `## Surface invariants` | Todo 3 |
| thot section | `## Names` | Todo 3 |
| Quality check labels | `RED executed`, `Mock boundary`, `Resource cost`, `Recovery paths`, `Timeless findings`, `Guard searches` | Todo 3 |
| imhotep section | `## Preflight` | Todo 5 |
| Blocked field | `Class: env \| plan` | Todo 5 |

## Todos

- [x] 1. Install the context7 MCP server that the README already requires
      Files: ~/.config/opencode/opencode.json (machine-local, outside this repository)
      Steps:
        1. Read the current file; confirm it holds only `$schema`.
        2. Add an `mcp.context7` entry with `type: remote`, `url: https://mcp.context7.com/mcp`
           and `headers: { "CONTEXT7_API_KEY": "{env:CONTEXT7_API_KEY}" }`.
        3. Add a top-level `permission` block with `"context7_*": "deny"`. The global deny keeps the
           tool definitions out of imhotep's context; thot re-enables them in Todo 2.
        4. Do not touch `opencode.jsonc` (D9). Do not add any other MCP server.
      Acceptance: the file parses as JSON, contains exactly one `mcp` entry named `context7`, and a
        top-level `permission."context7_*"` of `"deny"`. The `tools` field appears nowhere (D2).
        RED: with the `mcp` key removed the first QA command still parses but the key assertion in
        the second command fails.
      QA: happy: `python3 -c "import json,os;d=json.load(open(os.path.expanduser('~/.config/opencode/opencode.json')));print(list(d['mcp']),d['permission']['context7_*'])"`
            -> `['context7'] deny`
          failure: `grep -c '"tools"' ~/.config/opencode/opencode.json` -> `0`
          note: `opencode mcp list` is not usable here; the running process loaded its config at
            startup (Execution rule 11). Registration is proven in F4.

- [x] 2. thot: require a traced call chain for framework behaviour
      Files: agent/thot.md
      Steps:
        1. In the `permission` block (`agent/thot.md:6-27`) add `"context7_*": allow`. Leave every
           existing entry untouched, especially `task: allow` at `:27`.
        2. Rewrite Flow rule 2 (`:58-59`) into two paths. For claims about how a dependency behaves
           at runtime: inspect the dependency source, delegating to `task(subagent_type="scout")`
           when it is not already on disk. For API surface, signatures, versions and configuration
           keys: `context7_resolve-library-id` then `context7_query-docs`, using the prefixed names.
        3. Add one sentence: the absence of a symbol from one class is not evidence; a behavioural
           claim needs the executed call chain as `file:line`, or a measured probe.
      Acceptance: `agent/thot.md` contains `context7_resolve-library-id`, `context7_query-docs`,
        `scout` and the "absence" sentence; the unprefixed forms no longer appear as standalone tool
        names; the `permission` block still contains every entry it had before plus `"context7_*"`.
        RED: measured at plan time, `grep -c 'context7_\*' agent/thot.md` returns `0`. It returns
        `1` only after step 1.
      QA: happy: `grep -c 'context7_query-docs\|context7_resolve-library-id\|scout' agent/thot.md`
            -> at least `3`
          happy: `grep -c 'task: allow' agent/thot.md` -> `1`
          failure: `grep -c 'context7_\*' agent/thot.md` -> `1`
            (measured before the change: `0`)

- [x] 3. thot: six quality checks, two template sections, honest todo budget
      Files: agent/thot.md
      Steps:
        1. Add to `## Planning quality checks` (`:81-99`), one line each:
           `RED executed` — every RED condition is run before handoff and the QA line states the
           observed output;
           `Mock boundary` — assertions about filter output, ERROR dispatch, response headers or
           body serialization are not verified through a mocked servlet stack;
           `Resource cost` — every new read path states its query behaviour per request;
           `Recovery paths` — a catch block must not itself throw, and the cause is logged;
           `Timeless findings` — `## Findings` records no worktree state;
           `Guard searches` — a guard search may not be a bare common verb; it is executed at plan
           time and its hit count recorded.
        2. Change the todo budget at `:114` from 5-8 to 5-10.
        3. Add `## Surface invariants` to the plan template (`:121-177`), between `## Findings` and
           `## Decisions`: mandatory whenever the plan states an invariant that holds across a whole
           surface. A table of entry path against invariant, every cell filled. An empty cell blocks
           handoff.
        4. Add `## Names` to the template after `## Decisions`: a registry of new URL paths, bean
           names, test controller mappings and DTO field names across all todos.
        5. Add both sections to `## Self-check before handoff` (`:207-218`).
      Acceptance: both headings appear in the template block and in the self-check list; all six
        check labels are present; `:114` reads 5-10; the verbatim `## Execution rules` block is
        unchanged except for what Todo 4 adds.
        RED: measured at plan time, `grep -c '5–8\|5-8' agent/thot.md` returns `1`. Step 2 is the
        only way it reaches `0`.
      QA: happy: `grep -c 'RED executed\|Mock boundary\|Resource cost\|Recovery paths\|Timeless findings\|Guard searches' agent/thot.md`
            -> at least `6`
          happy: `grep -c 'Surface invariants' agent/thot.md` -> at least `2`
          failure: `grep -c '5–8\|5-8' agent/thot.md` -> `0`
            (measured before the change: `1`)

- [x] 4. Stage per todo instead of leaving everything untracked
      Files: agent/thot.md, agent/imhotep.md
      Steps:
        1. In the Execution rules template block (`agent/thot.md:131-141`) extend rule 5: at
           checkpoint, stage the todo's own files with `git add -- <Files>`. Rule 2 stays unchanged.
        2. Add a template rule forbidding `git stash` while staged plan work exists.
        3. Mirror both into `## Checkpoint before stop` (`agent/imhotep.md:86-97`) as a concrete step
           before the todo is marked.
        4. Remove `git stash` from the allowed list at `agent/imhotep.md:146`.
        5. Note in the template that scope verification uses `git diff --cached --name-only`, which
           makes baseline snapshot files unnecessary.
      Acceptance: `git add --` appears in thot's template rule 5 and in imhotep's checkpoint section;
        `git stash` appears in `agent/imhotep.md` only on a line that also forbids it; the blocked
        command list at `agent/imhotep.md:12-20` is unchanged.
        RED: before this todo, `git stash` sits in the allowed list at `agent/imhotep.md:146` and
        the third QA command returns `0`. Measured at plan time.
      QA: happy: `grep -c 'git add --' agent/thot.md` -> at least `1`
          happy: `grep -c 'git add --' agent/imhotep.md` -> at least `1`
          happy: `grep -c 'git stash.*[Nn]ever\|[Nn]ever.*git stash' agent/imhotep.md` -> at least `1`
            (measured before the change: `0`)
          failure: `git diff -- agent/imhotep.md | grep -c '^[-+].*git commit'` -> `0`
          failure: `grep -n 'git stash' agent/imhotep.md` -> no hit inside the `Allowed:` sentence
            that spans `agent/imhotep.md:145-146`

- [x] 5. imhotep: preflight, blocker classification, hard limits; README reality check
      Files: agent/imhotep.md, README.md
      Steps:
        1. Add `## Preflight` after `## First action`, run once per session with one line of output.
           It checks the assumptions the README currently gets wrong: the `caveman` skill resolves;
           `context7_*` is reachable when the plan needs external facts; `rg` is absent so searches
           use `git grep` or `grep`; docker, the project lint entry point and the build cache are
           usable. `## First action` itself stays byte-identical (D11).
        2. Extend the `Blocked:` format with a `Class: env | plan` line. An `env` blocker goes to the
           user, never to thot.
        3. Add a rule: long build or test commands run with an explicit bash timeout of 600000 ms;
           the tool default of 120000 ms is not a build failure.
        4. Add `task:` with `"*": deny` to the frontmatter `permission` block (D4).
        5. Add a rule: the project lint entry point runs after every implementation todo, not only in
           final verification.
        6. `README.md:20` — correct the skill path to `~/.agents/skills/<name>/SKILL.md`.
        7. `README.md:57` — stop presenting `rg` as available; state that the allowlist contains it
           but the tool may be missing, and that `git grep` or `grep` are the portable choice.
        8. `README.md:26` — use the prefixed names `context7_resolve-library-id` and
           `context7_query-docs`.
        9. `README.md:22-42` — mark the MCP block as a required installation step rather than an
           example, and show the `permission` form from Todo 1 (D2).
      Acceptance: `## Preflight` exists; `Class:` appears in the blocked format; `600000` appears;
        the frontmatter has `task:` with `"*": deny`; `## First action` is byte-identical to HEAD
        (D11); the four README statements match reality.
        RED: measured at plan time, `grep -c '\.config/opencode/skills' README.md` returns `1` and
        `grep -c '## Preflight' agent/imhotep.md` returns `0`. Both flip only through this todo.
      QA: happy: `grep -c '## Preflight' agent/imhotep.md` -> `1`
            (measured before the change: `0`)
          happy: `grep -c 'Class: env' agent/imhotep.md` -> at least `1`
          happy: `grep -c '600000' agent/imhotep.md` -> at least `1`
          happy: `grep -c 'context7_resolve-library-id' README.md` -> at least `1`
          happy: `grep -c '\.agents/skills' README.md` -> at least `1`
          failure: `git diff -- agent/imhotep.md | grep -c '^-.*active agent is Imhotep'` -> `0`
          failure: `grep -c '\.config/opencode/skills' README.md` -> `0`
            (measured before the change: `1`)

- [x] 6. Stop plans from growing: replace amendments, shrink checked todos, read review context on demand; make the per-todo lint rule conditional
      Files: agent/thot.md, agent/imhotep.md, command/start-work.md
        (step 4 edits `agent/imhotep.md:48` and `:159`, two lines written by the completed Todo 5;
        this is the amendment for D13 and is the only permitted reopening of Todo 5's output)
      Acceptance: thot's amendment section instructs deletion of a refuted finding; imhotep's
        checkpoint names `Steps:` and `QA:` as removed and `Files:` and `Acceptance:` as retained;
        neither `agent/imhotep.md` nor `command/start-work.md` instructs an unconditional read of
        the review context; the lint rule at `agent/imhotep.md:159` carries an explicit "when the
        project defines one" condition and a skip path, and `agent/imhotep.md` stays at most `6300`
        bytes so F2 still passes.

## Final verification

- [x] F1. Plan compliance: every implementation todo is checked and implemented as described.
      `git diff --cached --name-only` lists exactly these six paths and nothing else:
      `README.md`, `agent/imhotep.md`, `agent/thot.md`, `command/start-work.md`,
      `docs/plans/agent-token-and-correctness-fixes-plan.md` and
      `docs/plans/agent-token-and-correctness-fixes-plan.review-context.md`. The two plan files are
      part of the staged set by construction: Execution rule 5 (`agent/thot.md:148`,
      `agent/imhotep.md:108`) has imhotep persist facts and check off the todo in the plan itself
      before staging. Untracked IntelliJ files (`.idea/*`, `agents.iml`) predate this plan and are
      not scope violations; they must not be staged.
      `~/.config/opencode/opencode.json` lies outside the repository and is verified separately with
      the Todo 1 QA command.
- [x] F2. Prompt budget: `wc -c agent/imhotep.md` is at most `6300` (from `5070`) and
      `wc -c agent/thot.md` is at most `11000` (from `8953`). Growth beyond that means a rule was
      restated instead of stated once (`agent/thot.md:99`).
- [x] F3. Scope fidelity: nothing from `Must-NOT-Have` was built. Verify each of the following:
      (a) `git diff -- agent/thot.md | grep -c '^[-+].*docs/plans/<slug>-plan.md'` -> `0`;
      (b) `git diff -- agent/imhotep.md | grep -c '^[-+].*git commit'` -> `0`;
      (c) `grep -c 'Refs:' agent/thot.md agent/imhotep.md` -> `0` for both files;
      (d) `git diff -- agent/imhotep.md | grep -c '^-.*active agent is Imhotep'` -> `0`;
      (e) `grep -c '"tools"' ~/.config/opencode/opencode.json` -> `0`;
      (f) `~/.config/opencode/opencode.jsonc` is unchanged: it still contains only `$schema` and its
      byte count is `50`;
      (g) `python3 -c "import json,os;print(len(json.load(open(os.path.expanduser('~/.config/opencode/opencode.json')))['mcp']))"`
      -> `1`.
- [x] F4. Behaviour after restart: restart opencode, then `opencode mcp list` shows `context7`. In a
      thot session `context7_resolve-library-id` is offered; in an imhotep session it is not, and the
      task tool offers no subagent. This is the only behavioural check in this plan (D10) and
      requires the user to restart and confirm.

## Success criteria

- thot cannot hand off a plan whose surface-wide invariant leaves an entry path unaccounted for.
- thot's RED conditions carry an observed result, not a predicted one.
- A missing skill, a missing CLI tool or an unreachable MCP server is caught in preflight and
  reported as `Class: env`, never routed to thot.
- imhotep cannot delegate implementation to a subagent.
- Completed work is staged, so `git grep` sees the plan's own output and `git status --short`
  separates plan work from foreign changes.
- A repaired plan does not grow, and a checked todo costs a title, its files and its acceptance line.
