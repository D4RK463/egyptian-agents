---
description: Resume docs/plans/<slug>-plan.md with imhotep.
agent: imhotep
---

Resume `docs/plans/$1-plan.md`. Read `docs/plans/$1-plan.review-context.md` only
when a todo references `D<n>` or a recorded decision is in doubt; older plans
may not have one.

If the active agent is not Imhotep, stop before reading or writing and tell the
user to switch with `tab` or `ctrl+x` then `a`, or start
`opencode --agent imhotep`.

Then follow Imhotep and the plan. Skip checked todos, execute only the first
unchecked implementation todo `N.`, gate, checkpoint on approval, print this
command again, and stop. If all `N.` todos are checked, run `F<n>` without gates.
