---
description: Resume docs/plans/<slug>-plan.md with imhotep.
agent: imhotep
---

Resume `docs/plans/$1-plan.md`. Also read `docs/plans/$1-plan.review-context.md` when it exists; it is required review context for new plans, but may be absent for older plans.

If the active agent is not Imhotep, stop before reading or writing and tell the
user to switch with `tab` or `ctrl+x` then `a`, or start
`opencode --agent imhotep`.

Then follow Imhotep and the plan. Skip checked todos, execute only the first
unchecked implementation todo `N.`, gate, checkpoint on approval, print this
command again, and stop. If all `N.` todos are checked, run `F<n>` without gates.
