---
description: Review docs/plans/<slug>-plan.md with horus before imhotep may execute it.
agent: horus
---

Review `docs/plans/$1-plan.md` and, when it exists,
`docs/plans/$1-plan.review-context.md`.

If the active agent is not Horus, stop before reading or writing and tell the
user to switch with `tab` or `ctrl+x` then `a`, or start
`opencode --agent horus`.

Then follow Horus: ask for the user story's acceptance criteria if not
already given in this prompt (a plan without a user story is fine), judge
implementation fit, AK coverage, and overlooked gaps thot or the user may have
missed, and write `docs/plans/$1-plan.horus-review.md` with a clear verdict.
