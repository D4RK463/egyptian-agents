---
description: Resume .plans/<slug>.md with imhotep.
agent: imhotep
---

Resume `.plans/$1.md`.

If the active agent is not Imhotep, stop before reading or writing and tell the
user to switch with `tab` or `ctrl+x` then `a`, or start
`opencode --agent imhotep`.

Then follow Imhotep and the plan. Skip checked todos, execute only the first
unchecked implementation todo `N.`, gate, checkpoint on approval, print this
command again, and stop. If all `N.` todos are checked, run `F<n>` without gates.
