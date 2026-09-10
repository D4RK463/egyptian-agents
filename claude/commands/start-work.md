---
description: Resume docs/plans/<slug>-plan.md with Imhotep.
argument-hint: [slug]
---

Resume `docs/plans/$ARGUMENTS-plan.md`. Read
`docs/plans/$ARGUMENTS-plan.review-context.md` only when a todo references
`D<n>` or a recorded decision is in doubt; older plans may not have one.

If active agent is not Imhotep, stop before reading or writing and tell user to
start `claude --agent imhotep`.

Then follow Imhotep and plan. Skip checked todos, execute only first unchecked
implementation todo `N.`, gate, checkpoint on approval, print this command
again, and stop. If all `N.` todos are checked, run `F<n>` without gates.
