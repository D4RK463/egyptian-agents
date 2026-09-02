# plan-files-english — Work Plan

## TL;DR
**What you get:** `agent/thot.md` states one unambiguous language rule — chat
responses follow the user's language, plan files under `.plans/` are always
English.
**Why:** The plan file is re-read by imhotep on every turn; German tokenizes
~1.3–1.5x worse. It also removes a hard contradiction inside thot's own prompt.
**What it does NOT do:** No translation of existing plan files, no change to
imhotep's response language, no frontmatter changes, no new features.
**Effort:** 3 todos, pure prompt text.
**Risk:** Low — text-only, verifiable with grep assertions.

## Execution rules (binding for the executing agent)

1. Load the skill first: `skill(name="caveman")`. Do not work without the skill loaded.
   Every user-facing output is caveman-terse. Code, commands, error messages, and
   identifiers stay exact.
2. No commits. `git commit`, `push`, `merge`, `rebase`, `reset`, `tag` are forbidden.
   Commit suggestions are emitted only as a copyable command.
3. Review gate after EVERY todo: implement -> run QA -> stop -> call `question`
   (changes, QA evidence, commit suggestion, options continue/rework/stop).
   Only after an explicit "weiter" / "continue" is `- [x]` set and the next todo started.
   Stopping is correct behavior, not laziness. Never bundle two todos in one gate.
4. `Must-NOT-Have` is binding. Extra ideas go as a note into `## Findings`, not into code.
5. Plan wrong or reality differs: stop, report, hand back to thot. Do not replan yourself.

## Environment constraints for QA

Binding for ALL QA and acceptance commands in this plan:

- **No `git`.** Repo has zero commits (`fatal: Ihr aktueller Branch 'master'
  hat noch keine Commits.`). `git diff` / `git status` yield no usable evidence.
- **No `rg`, no `fd`.** Neither is installed. All searches use GNU `grep`.
- All commands run from repo root.
- A command "outputs nothing" when `grep` prints no line (exit code 1).

## Scope

**In:**
- `agent/thot.md` — rewrite `## Output language` (currently lines 36–41) so plan
  files are always English, chat responses follow the user's language
- `agent/thot.md` — reinforce the rule at the Phase 4 / `## Execution rules`
  verbatim-copy instruction so no ambiguity remains
- Consistency pass over `agent/imhotep.md`, `command/start-work.md`, `README.md`

**Out:**
- Existing files under `.plans/` — not translated, not touched
- YAML frontmatter of all files
- `install.sh`
- The `caveman` skill and anything under `~/.config/opencode/`
- Any use of `git`, including read-only

**Must-NOT-Have:**
- No change to imhotep's response language rule (chat stays user language)
- No new sections, agents, or commands
- No rewording of the `## Execution rules` block content itself
- No auto-translation tooling

## Findings
- `agent/thot.md:36-41` — `## Output language`: "Responses and plan files follow
  the user's language". Source of German plan files.
- `agent/thot.md:237-239` — "Copy the `## Execution rules` block **verbatim**
  into every plan." Direct contradiction with line 38 for non-English users.
- `.plans/english-agent-prompts.md:15-29` — evidence the contradiction fires in
  practice: the Execution rules block was translated to German, violating :237.
- `README.md:138-142` — `## Language` already documents "Prompts and plan files
  use English". README is correct; `thot.md` drifted from it. No README change
  needed, only verification.
- `agent/imhotep.md:44-49` — imhotep's rule covers responses only, not plan
  files. Correct as-is, verify only.
- `command/start-work.md` — no language rule. Correct as-is, verify only.
- `.plans/english-agent-prompts.md:6-7` — prior measurement basis: "~30% weniger
  Prompt-Tokens" for the English switch.

## Decisions
- **Plan files always English, chat always user language** — the plan is a
  machine-consumed artifact re-read every executor turn; the approval brief in
  chat carries the human-facing explanation. Rejected: full German, because it
  costs tokens on every turn and breaks the verbatim-copy rule. Rejected: full
  English including chat, because the user explicitly writes German and
  approval quality drops.
- **README stays unchanged** — it already states the target rule. Rejected:
  rewriting it, that would be churn without content change.
- **No translation of existing `.plans/*.md`** — they are historical artifacts;
  rewriting them risks corrupting executable task lines for zero gain.

## Todos

- [x] 1. Rewrite `## Output language` in thot.md
      Files:      agent/thot.md
      Steps:      Replace the paragraph at lines 36-41 (section `## Output
                  language`). New content must state, in this order:
                  (a) chat responses follow the user's language, defaulting to
                  their latest message;
                  (b) plan files under `.plans/` are ALWAYS English, regardless
                  of the user's language, because the executor re-reads them
                  every turn and the `## Execution rules` block is copied
                  verbatim;
                  (c) these instructions stay English;
                  (d) keep code, commands, paths, `file:line` references,
                  identifiers, error messages, `THOT: PLAN MODE`, plan template
                  section names, and task-line prefixes exact in every language.
                  Keep the heading `## Output language` unchanged.
      Acceptance: Section exists, contains the literal string `.plans/`, and no
                  longer contains the string `Responses and plan files follow`.
      QA:         happy: grep -n "plan files" agent/thot.md -> at least one line
                  inside the `## Output language` section stating plan files are
                  always English
                  failure: grep -c "Responses and plan files follow the user" agent/thot.md
                  -> prints `0`
      Commit (suggested): docs(thot): make plan files always English

- [x] 2. Reinforce the rule at the verbatim-copy instruction
      Files:      agent/thot.md
      Steps:      At the paragraph after the plan template that mandates copying
                  `## Execution rules` verbatim (currently lines 237-239), append
                  one sentence: the block is English and is never translated,
                  consistent with `## Output language`. Also extend the
                  `### Self-check before handoff` list with one bullet asserting
                  the plan file is written in English.
      Acceptance: The verbatim-copy paragraph mentions "translate" or
                  "translated"; `### Self-check before handoff` has one more
                  bullet than before, referencing English.
      QA:         happy: grep -n "verbatim" agent/thot.md -> paragraph found, and
                  the following sentence forbids translation
                  failure: grep -A8 "Self-check before handoff" agent/thot.md
                  -> bullet list contains a line mentioning English
      Commit (suggested): docs(thot): forbid translating execution rules block

- [x] 3. Consistency pass across the remaining prompt files
      Files:      agent/imhotep.md, command/start-work.md, README.md
      Steps:      Read the `## Output language` section in `agent/imhotep.md`
                  and `## Language` in `README.md`. Confirm neither contradicts
                  the new thot rule. Change ONLY if a contradiction exists; if
                  a file is already consistent, leave it byte-identical and say
                  so in the gate report. `command/start-work.md` has no language
                  rule — confirm and leave unchanged.
      Acceptance: Either no edit was needed (stated explicitly with the quoted
                  lines as evidence), or the contradicting sentence was fixed.
      QA:         happy: grep -n -i "language" agent/imhotep.md command/start-work.md README.md
                  -> every hit is consistent with "plan files are English,
                  responses follow user language"
                  failure: grep -n "plan files follow the user" agent/imhotep.md README.md
                  -> prints nothing
      Commit (suggested): docs: align language rules across prompts

## Final verification

- [x] F1. Plan compliance: every todo implemented as described
- [x] F2. Frontmatter intact: grep -n "^mode: primary" agent/thot.md and
      grep -n "^description:" agent/thot.md both print a line
- [x] F3. Structure intact: grep -c "^## " agent/thot.md prints the same count
      as before the change (17; includes headings inside the template fence)
- [x] F4. Scope fidelity: no file under `.plans/` other than this one was
      modified; `install.sh` untouched

## Success criteria
- `agent/thot.md` contains exactly one language rule, and it says plan files are
  always English while chat follows the user
- The contradiction between `## Output language` and the verbatim-copy rule is
  gone
- `README.md:138-142` and `agent/thot.md` agree
- No existing plan file was translated or otherwise modified
