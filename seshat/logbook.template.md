# Seshat Logbook

Personal learning record of the developer. Local only: never commit it, never
copy entries into a repository, plan, or ticket.

thot reads it while planning and adds patterns the developer answered about.
seshat reads it while executing and records passed learning tasks. Both follow
the rules below; they are the single source for levels and decay.

## Rules

- **Pattern:** one recurring backend building block, generic across projects.
  Id is kebab-case, e.g. `rest-endpoint`, `service-transaction`,
  `jpa-custom-query`, `dto-mapping`, `flyway-migration`, `config-properties`,
  `security-rule`, `scheduled-job`, `message-listener`, `dockerfile`, `ci-job`.
  Reuse an existing id before creating a new one.
- **Done:** times the developer implemented the pattern and passed seshat's
  check without `zeig lösung` / `show solution` / `mach du` / `you do it`.
- **Global level:** Done 0 -> `new`; Done 1-2 -> `seen`; Done >= 3 or
  `Known: self-reported` -> `confident`.
- **Decay:** `Last` older than 90 days -> one level lower (`confident` ->
  `seen` -> `new`). Self-reported knowledge without `Last` does not decay.
- **Effective level in a project:** `new` while the current project's entry
  is missing or has Done 0; otherwise the global level.
- **Project name:** basename of `git rev-parse --show-toplevel`.

## Patterns

<!--
Entry shape, one per pattern:

### rest-endpoint — REST endpoint (controller -> service -> repository)
- Done: 0
- Last: -
- Known: no | self-reported
- Projects:
  - shop-backend: `src/main/kotlin/.../OrderController.kt:40` — Done 0
-->
