---
description: Review docs/plans/<slug>-plan.md with Horus before Imhotep may execute it.
argument-hint: [slug]
---

Review `docs/plans/$ARGUMENTS-plan.md` and, when it exists,
`docs/plans/$ARGUMENTS-plan.review-context.md`.

If active agent is not Horus, stop before reading or writing and tell user to
start `claude --agent horus`.

Then follow Horus: ask for the user story's acceptance criteria if not
already given in this prompt (a plan without a user story is fine), judge
implementation fit, AK coverage, and overlooked gaps thot or the user may have
missed, and write `docs/plans/$ARGUMENTS-plan.horus-review.md` with a clear
verdict.
