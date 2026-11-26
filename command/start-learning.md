---
description: Resume docs/plans/<slug>-plan.md with seshat (learning mode).
agent: seshat
---

Resume `docs/plans/$1-plan.md` in learning mode. Read
`docs/plans/$1-plan.review-context.md` only when a todo references `D<n>` or a
recorded decision is in doubt; older plans may not have one.

If the active agent is not Seshat, stop before reading or writing and tell the
user to switch with `tab` or `ctrl+x` then `a`, or start
`opencode --agent seshat`.

Horus review is optional. If `docs/plans/$1-plan.horus-review.md` exists and
carries `Verdict: CHANGES_REQUESTED`, Seshat refuses to run until thot amends
the plan.

Then follow Seshat and the plan. Skip `- [x]` todos. On a `- [~]` todo, resume
the check loop. Otherwise execute only the first `- [ ]` implementation todo:
learning todos get a skeleton handoff, other todos a normal gate. Checkpoint on
approval, print this command again, and stop. If all `N.` todos are checked,
run `F<n>` without gates.
