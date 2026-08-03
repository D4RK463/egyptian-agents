---
description: Execute a plan from .plans/<slug>.md with imhotep. Stops after every todo for review.
agent: imhotep
---

Execute plan `$1`.

1. Verify that the active agent is Imhotep. If not, stop without reading or
   writing anything. Tell the user to switch with `tab` or `ctrl+x` then `a`,
   or start `opencode --agent imhotep`.
2. Load the `caveman` skill first.
3. Read `.plans/$1.md`.
   - If `$1` is empty or the file does not exist: list all files in `.plans/`
     and ask which plan is intended. Do not guess.
4. Read and follow the `## Execution rules` section in the plan file. It is
   binding. Do not skip it.
5. Mirror `## Todos` into `todowrite`.
6. Work through todos strictly in order.

Reminder of the three rules most often broken here:

- Stop after **every** todo and call `question`. Even for tiny todos. Check it
  off only after explicit `"weiter" / "continue"`.
- **No commits.** Emit the commit suggestion as a copyable command.
- `Must-NOT-Have` is binding. Put extra ideas as a note in `## Findings`, not
  into code.
