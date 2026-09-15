---
description: Resume docs/plans/<slug>-plan.md with Imhotep.
argument-hint: [slug]
---

Resume `docs/plans/$ARGUMENTS-plan.md`. Read
`docs/plans/$ARGUMENTS-plan.review-context.md` only when a todo references
`D<n>` or a recorded decision is in doubt; older plans may not have one.

If active agent is not Imhotep, stop before reading or writing and tell user to
start `claude --agent imhotep`.

Horus review is optional: imhotep runs without a
`docs/plans/$ARGUMENTS-plan.horus-review.md`. If that file exists and carries
`Verdict: CHANGES_REQUESTED`, imhotep refuses to run until thot amends the
plan; run `/review-plan $ARGUMENTS` if you want a review.

Then follow Imhotep and plan. Skip checked todos, execute only first unchecked
implementation todo `N.`, gate, checkpoint on approval, print this command
again, and stop. If all `N.` todos are checked, run `F<n>` without gates.
