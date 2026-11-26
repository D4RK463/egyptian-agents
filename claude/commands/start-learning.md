---
description: Resume docs/plans/<slug>-plan.md with Seshat (learning mode).
argument-hint: [slug]
---

Resume `docs/plans/$ARGUMENTS-plan.md` in learning mode. Read
`docs/plans/$ARGUMENTS-plan.review-context.md` only when a todo references
`D<n>` or a recorded decision is in doubt; older plans may not have one.

If active agent is not Seshat, stop before reading or writing and tell user to
start `claude --agent seshat`.

Horus review is optional. If `docs/plans/$ARGUMENTS-plan.horus-review.md`
exists and carries `Verdict: CHANGES_REQUESTED`, Seshat refuses to run until
thot amends the plan.

Then follow Seshat and the plan. Skip `- [x]` todos. On a `- [~]` todo, resume
the check loop. Otherwise execute only the first `- [ ]` implementation todo:
learning todos get a skeleton handoff, other todos a normal gate. Checkpoint on
approval, print this command again, and stop. If all `N.` todos are checked,
run `F<n>` without gates.
