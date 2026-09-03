# agent-token-and-correctness-fixes — Review Context

## Purpose

Read this before reviewing the plan or the implementation. Do not propose changes that reverse a
recorded decision without new, concrete evidence.

The plan reacts to a measured episode: the public catalog API work in `bss-modulith` between
2026-08-28 and 2026-09-02. 62 sessions, $78.17, 23 `Blocked:` reports, three plans, two external
review rounds that had to be worked off afterwards. All figures below come from the opencode session
store and from the files in that repository.

## Decisions and assumptions

### D1. context7 was never installed; thot's rule was unexecutable, not ignored

- **Status:** confirmed
- **Rationale:** The obvious reading of "zero context7 calls in 62 sessions" is that the agent
  ignored its instruction. It could not have followed it. This changes the fix from rewording a
  prompt to completing an installation the README already prescribed.
- **Evidence:** `README.md:22-42` declares the server required and prints the install block; before
  Todo 1, `~/.config/opencode/opencode.json` was 51 bytes containing only `$schema`; Todo 1 added
  the `context7` entry and `permission."context7_*": "deny"`, verified by JSON parsing. The
  opencode session store returns no tool part matching `%context7%` for `bss-modulith` since
  2026-08-28.
- **Rejected alternatives:** Sharpening the prompt wording — it would not have created the server.
  Dropping the rule as unused — it addresses seven of the observed blockers.
- **Constraints / validity:** `CONTEXT7_API_KEY` is unset. The server works without a key at a lower
  rate limit. If throttling appears, obtain a key rather than removing the rule.

### D2. Use `permission`, never the deprecated `tools` field

- **Status:** confirmed
- **Rationale:** An earlier draft of this plan proposed `"tools": { "context7*": false }`. The
  opencode documentation marks that field deprecated and directs new configuration to `permission`.
- **Evidence:** opencode docs `/docs/agents#tools-deprecated`. The same page notes that permission
  keys are matched as wildcard patterns against the underlying tool name, which is what makes
  `"context7_*"` work for MCP tools.
- **Rejected alternatives:** The `tools` field — works today, deprecated tomorrow.
- **Constraints / validity:** MCP tools are registered with the server name as prefix. Renaming the
  server in `opencode.json` invalidates every `context7_*` pattern in `agent/thot.md`.

### D3. `scout` for dependency source, context7 for API surface

- **Status:** confirmed
- **Rationale:** All seven framework fact errors were assertions about how compiled dependency code
  behaves, which documentation would not have settled. Context7 alone would have missed them.
- **Evidence:** the `ProblemDetail.instance` claim was refuted by
  `RequestResponseBodyMethodProcessor:203`; the Jackson 2 versus Jackson 3 mixin conflict, the
  `sendError` bypass of the controller advice, and the `internal` visibility across Kotlin source
  sets are all source or build-configuration facts. opencode docs `/docs/agents#use-scout` describes
  `scout` as a read-only agent for cloning and inspecting dependency source. thot already holds
  `task: allow` (`agent/thot.md:27`), so no permission change is needed.
- **Rejected alternatives:** context7 alone — wrong instrument for source behaviour. A new custom
  subagent — `scout` already exists and is read-only by construction.
- **Constraints / validity:** `scout` clones into opencode's managed cache. If that cache is
  unavailable the claim must be traced against the local Gradle or Maven dependency cache instead;
  either way the acceptable evidence is a call chain, not a class-name search.

### D4. `permission.task: deny` instead of a prompt rule

- **Status:** confirmed
- **Rationale:** A prompt rule already failed. During the catalog work imhotep delegated todo 5 to
  the `general` subagent: 2.8M tokens, 12 `apply_patch` calls, without the plan, the
  `Must-NOT-Have`, or the commit ban. A configuration deny is mechanical and cheaper than the
  sentence that would ask for the same thing.
- **Evidence:** opencode docs `/docs/agents#task-permissions` — `deny` removes the subagent from the
  Task tool description entirely, so the model does not attempt the call. Session
  `ses_fa86c4754ffeXUEAArifj7wwVj`, agent `general`, 127k input tokens, invoked from an imhotep
  session.
- **Rejected alternatives:** A prohibition sentence in the prompt — costs tokens and is advisory.
  Denying only `general` — any subagent reproduces the gap.
- **Constraints / validity:** If imhotep ever legitimately needs parallel work, this must be
  reopened as an owner decision rather than relaxed silently. thot keeps `task: allow`; its use of
  `explore` and `scout` is unaffected.

### D5. Stage per todo; the commit ban stays

- **Status:** confirmed (user decision)
- **Rationale:** Four blockers came from git blindness: `git grep` silently reporting zero hits for
  untracked plan output, `git status` unusable as a scope oracle, `.gitignore` noise failing F1, and
  a "worktree is clean" finding written as a timeless fact. Staging removes all four without
  granting commit rights.
- **Evidence:** `Blocked: todo 6 QA cannot run as specified. Why: git grep -c "" --
  docs/architecture/public-api.md -> no output; file untracked, git grep searches tracked files
  only.` and `Blocked: final verification F1 failed. Why: git status --short shows .gitignore, not
  allowed by todo Files or baseline.`
- **Rejected alternatives:** A commit per todo — rejected by the owner. Keeping the status quo and
  mandating `git grep --untracked` everywhere — treats the symptom and leaves the scope oracle
  broken. That workaround was in fact added to the followup plan as Execution rule 10 and still did
  not fix F3.
- **Constraints / validity:** `git stash` must be removed from imhotep's allowed list
  (`agent/imhotep.md:146`), otherwise a stash can silently carry staged plan work away.

### D6. Shrinking a checked todo keeps `Files:` and `Acceptance:`

- **Status:** confirmed
- **Rationale:** `## Todos` in the catalog plan was 14 230 tokens with nine of ten todos checked,
  resident in every turn of every later session. `Steps:` and `QA:` are consumed once;
  `Acceptance:` is not.
- **Evidence:** F1 in every plan of this family reads "every todo implemented as described" and
  needs the acceptance line as its contract. Section measurement of that file: `## Todos` 14 230
  tokens, `## Findings` 7 709, `## Decisions` 3 983, total about 30 000.
- **Rejected alternatives:** Deleting the whole todo body — breaks F1. Moving bodies into the review
  context — duplicates content and re-inflates a file someone might read.
- **Constraints / validity:** Plans in this repository are tracked by git, so a shrunk body remains
  recoverable from history. For plans under an ignored directory it is not; there, a reworked todo
  must be re-specified by thot rather than recovered.

### D7. No `Refs:` lines and no selective plan reading

- **Status:** confirmed (user decision)
- **Rationale:** D6 and D-note on amendments already bring a plan of this size from about 30k to
  about 7-9k tokens. Selective reading would save perhaps 3k more at the cost of imhotep missing a
  relevant finding — the failure mode that produced the invented `primaryPrice.id` assertion.
- **Evidence:** measured section sizes above; `agent/imhotep.md:53-54` requires reading Scope,
  `Must-NOT-Have`, Findings and Decisions precisely because sessions are disposable.
- **Rejected alternatives:** `Refs: D3, F7` per todo with scoped reading.
- **Constraints / validity:** Revisit only if measured plan size stays above roughly 15k tokens
  after this plan lands.

### D8. Plan paths and filenames stay unchanged

- **Status:** confirmed (user decision)
- **Rationale:** An earlier analysis flagged `.plans/`, `docs/plans/` and a non-existent
  `.docs/plans/` as inconsistent. The inconsistency is legacy, not current.
- **Evidence:** commits `492291c` ("store plans in docs directory") and `fc8ca2d` ("require plan
  filename suffix") already unified the convention in this repository. Divergent legacy names under
  `bss-modulith` predate them. `agent/thot.md:104-105` and `command/start-work.md:6` are already
  consistent with each other.
- **Rejected alternatives:** Renaming existing plans; changing the convention again.
- **Constraints / validity:** Applies to new plans. Legacy plans are not retrofitted.

### D9. The `opencode.jsonc` duplicate is reported, not changed

- **Status:** assumption-to-verify
- **Rationale:** `~/.config/opencode/` holds both `opencode.json` (51 bytes) and `opencode.jsonc`
  (50 bytes), each with only `$schema`. Precedence between them is not documented in the pages
  consulted.
- **Evidence:** both files present with the stated sizes.
- **Rejected alternatives:** Deleting the `.jsonc` while writing the MCP block — an unrelated change
  to machine-local configuration, and a confounder if F4 fails.
- **Constraints / validity:** If F4 shows the MCP server is not picked up, precedence is the first
  suspect and this entry moves to `confirmed` or `superseded` accordingly.

### D10. Static acceptance; behaviour proven once in F4

- **Status:** confirmed
- **Rationale:** This plan edits the prompts of the agents executing it. opencode loads agent
  configuration at startup, so no todo can observe its own effect in the session that made it.
- **Evidence:** `install.sh` closes with "WICHTIG: opencode neu starten. Die Konfiguration wird nur
  beim Start geladen."
- **Rejected alternatives:** Behavioural acceptance per todo — would produce exactly the unreachable
  RED condition that Todo 3's `RED executed` rule exists to prevent. That is the same defect as
  `PublicProblemBodyIdentityTest.kt:46`, which asserted MVC behaviour without entering MVC and
  therefore stayed green while the defect shipped.
- **Constraints / validity:** F4 needs the user to restart opencode and confirm; it is the one
  acceptance criterion in this plan that is not agent-verifiable, and it is marked as such.

### D11. The imhotep identity guard stays

- **Status:** confirmed — supersedes an earlier draft assumption
- **Rationale:** An earlier draft proposed deleting `## First action` to save about 150 tokens,
  assuming the `agent: imhotep` frontmatter of `/start-work` switches the agent.
- **Evidence:** `README.md`, section "Switching agents": the `agent:` field in command frontmatter
  does not switch a `primary` agent; the command prompt runs under the currently active agent.
  `docs/plans/agent-switch-guard-plan.md` introduced the guard deliberately across four checked
  todos. Session `ses_fa7f214abffe7h25yi5QQL6Nxi` ran the `/start-work` prompt under the `build`
  agent, which is exactly the case the guard exists for.
- **Rejected alternatives:** Removing the guard; weakening it to a warning.
- **Constraints / validity:** The `Blocked: active agent not verified as Imhotep` report is correct
  behaviour, not waste. Todo 5 classifies it as `Class: env` so it stops being routed to thot.

### D12. Prompt tokens are near-free; plan tokens are not

- **Status:** confirmed
- **Rationale:** This governs every size tradeoff in the plan. It is the reason six new quality
  checks and a preflight section are acceptable, while a `## Surface invariants` table needed an
  explicit justification.
- **Evidence:** imhotep across 45 sessions: 42.7M `cache_read` against 2.1M fresh input and 0.25M
  output, average 20.6 turns per session and 949k `cache_read` per session. `agent/imhotep.md` is
  1 267 tokens against a plan file of about 30 000. 22 of 45 imhotep sessions ended in `Blocked:`
  for $19.99; thot repair sessions cost $8.19. Average failed session $0.91, average thot repair
  $1.64. The plan's own additions cost roughly $0.70 against roughly $23-28 of avoidable cost.
- **Rejected alternatives:** Optimising prompt length first — it targets about 2% of context.
- **Constraints / validity:** Holds while sessions average roughly 20 turns. If sessions become much
  shorter the ratio shifts and F2's byte budget should be re-derived rather than simply raised.

### D13. The per-todo lint rule is conditional on the project defining a lint entry point

- **Status:** confirmed — amends Todo 5, whose rule was written unconditionally
- **Rationale:** Todo 5 added "Run project lint entry point after every implementation todo" and
  listed the lint entry point among the preflight prerequisites whose absence is a `Class: env`
  blocker. Both sentences assume every project has one. This repository does not, so the rule made
  its own plan unexecutable: Todo 6 was reported as `Blocked: todo 6 missing project lint entry
  point`. A rule that blocks correct work is worse than no rule.
- **Evidence:** `agent/imhotep.md:159` (the unconditional rule), `agent/imhotep.md:48` (preflight
  prerequisite), `agent/imhotep.md:155` (`Class: env` classification). The repository contains only
  `agent/`, `command/`, `docs/`, `README.md` and `install.sh`; no `package.json`, no lint
  configuration, no CI workflow. `markdownlint` and `prettier` are not on `PATH`. The plan's own
  final verification defines no lint task: F2 is a byte budget, F3 is scope fidelity.
- **Rejected alternatives:** Introducing a lint entry point for this repository — new tooling and a
  new dependency, outside this plan's `Out` list and an owner decision. Dropping the per-todo lint
  rule entirely — it addresses a real gap in projects that do have lint, where defects surfaced only
  at final verification. Leaving the rule and letting imhotep judge — that judgement already failed
  once and produced a blocker instead of a skip.
- **Constraints / validity:** The skip applies only to a missing lint entry point. A missing skill,
  CLI tool, MCP server, docker or build cache stays `Class: env` and still blocks. If this
  repository later gains a lint entry point, the rule applies to it with no further change.

### D14. F1's staged file list includes the plan files themselves

- **Status:** confirmed — amends F1, which was written with a four-file list
- **Rationale:** F1 originally asserted that `git diff --cached --name-only` lists exactly the four
  edited source files. That contradicts the staging rule this same plan introduced: the checkpoint
  persists facts and checks off the todo *in the plan file*, then stages. The plan and its review
  context are therefore always part of the staged set, and F1 could never pass as written.
- **Evidence:** `agent/thot.md:148` and `agent/imhotep.md:108` — persist in the plan, then
  `git add -- <Files>`. Observed at F1 time: the staged set was `README.md`, `agent/imhotep.md`,
  `agent/thot.md`, `command/start-work.md` plus both plan files; the run was reported as
  `Blocked: final verification F1 failed`.
- **Rejected alternatives:** Unstaging the plan files before F1 — hides the plan's own history from
  `git grep` and reintroduces the untracked-file blindness that D5 removed. Dropping the file list
  from F1 — loses the scope oracle entirely.
- **Constraints / validity:** The list is exact for this plan. Any future plan writes its own two
  paths into F1. Untracked IntelliJ files must stay untracked; staging them is a scope violation.

## Findings not turned into scope

Recorded so a later reviewer does not mistake them for oversights.

- **`install.sh` does not verify prerequisites.** It links two paths and prints a reminder. Every
  prerequisite in the README — skills, MCP server, CLI tools, provider auth — is unverified at
  install time. Todo 5 moves the check into imhotep's preflight, which runs per session and
  therefore also catches drift after installation. Hardening `install.sh` as well was offered and
  deferred; it is out of scope here.
- **Missing tax-category names silently deleted an offering.** A review finding from the catalog
  work, already fixed there. It is the concrete case behind the `Recovery paths` and `Resource cost`
  checks in Todo 3 and is not re-litigated by this plan.
- **`## Future BFF extraction` in the catalog plan** occupied 921 tokens in every session without
  ever being executed. It is an argument for keeping speculative sections out of plan files, but no
  rule in this plan forbids them; thot's existing `Must-NOT-Have` mechanism is the intended place
  for that discipline.
