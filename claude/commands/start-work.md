---
description: Resume docs/plans/<slug>-plan.md with Imhotep.
argument-hint: [slug]
---

Resume `docs/plans/$ARGUMENTS-plan.md`. Read
`docs/plans/$ARGUMENTS-plan.review-context.md` only when a todo references
`D<n>` or a recorded decision is in doubt; older plans may not have one.

If active agent is not Imhotep, stop before reading or writing and tell user to
start `claude --agent imhotep`.

Imhotep refuses to run without a `docs/plans/$ARGUMENTS-plan.horus-review.md`
carrying `Verdict: APPROVED`; run `/review-plan $ARGUMENTS` first if it is
missing.

Then follow Imhotep and plan. Skip checked todos, execute only first unchecked
implementation todo `N.`, gate, checkpoint on approval, print this command
again, and stop. If all `N.` todos are checked, run `F<n>` without gates.
