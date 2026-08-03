# english-agent-prompts — Work Plan

## TL;DR
**Was du bekommst:** Alle drei Prompt-Dateien (`agent/thot.md`, `agent/imhotep.md`,
`command/start-work.md`) auf Englisch, inklusive Plan-Template, `## Execution rules`
und `## Stop Rules`. Neu: explizite Output-Sprach-Regel und zweisprachige
Trigger-Wörter am Review-Gate.
**Warum:** Bessere Instruction-Compliance, ~30% weniger Prompt-Tokens, späterer
Compaction-Punkt, kein Sprach-Leak in Commit-Messages.
**Was es NICHT tut:** Keine inhaltliche Regeländerung, kein Frontmatter-Eingriff,
keine neuen Features, keine Übersetzung bestehender Plandateien.
**Aufwand:** 6 Todos, überwiegend Textarbeit.
**Risiko:** Mittel — Prompt-Regressionen sind nicht automatisch testbar. Mitigation:
strikte Struktur-Parität (Abschnittszahlen, Zeilenformate, Frontmatter-Assertions).

## Execution rules (verbindlich für den ausführenden Agent)

1. Lade zuerst den Skill: `skill(name="caveman")`. Ohne geladenen Skill nicht arbeiten.
   Jede Ausgabe an den Nutzer ist caveman-terse. Code, Befehle, Fehlermeldungen und
   Bezeichner bleiben exakt.
2. Keine Commits. `git commit`, `push`, `merge`, `rebase`, `reset`, `tag` sind verboten.
   Commit-Vorschläge werden nur als kopierbarer Befehl ausgegeben.
3. Review-Gate nach JEDEM Todo: umsetzen -> QA laufen lassen -> anhalten -> `question`
   aufrufen (Änderungen, QA-Evidenz, Commit-Vorschlag, Optionen weiter/nacharbeiten/stop).
   Erst nach ausdrücklichem "weiter" wird `- [x]` gesetzt und das nächste Todo begonnen.
   Anhalten ist korrektes Verhalten, keine Faulheit. Niemals zwei Todos in einem Gate.
4. `Must-NOT-Have` ist bindend. Zusatzideen als Notiz in `## Findings`, nicht in Code.
5. Plan falsch oder Realität weicht ab: stoppen, melden, zurück an thot. Nicht selbst umplanen.

## Umgebungsvorgaben für die QA

Diese Regeln gelten für ALLE QA- und Acceptance-Befehle in diesem Plan:

- **Kein `git`.** Das Repo hat null Commits (`fatal: Ihr aktueller Branch 'master'
  hat noch keine Commits.`). `git diff`, `git status --short` und `git diff --stat`
  liefern keine verwertbare Evidenz und werden nicht verwendet.
- **Kein `rg`, kein `fd`.** Beide sind nicht installiert (`rg: Befehl nicht gefunden`).
  Jede Suche läuft über GNU `grep` 3.11.
- Alle Befehle werden aus dem Repo-Root ausgeführt.
- Ein Befehl gilt als "gibt nichts aus", wenn `grep` keine Zeile ausgibt (Exit-Code 1).
- Als Ersatz für den Frontmatter-Diff dienen positive Assertions auf die kritischen
  Frontmatter-Zeilen. Fehlt eine, wurde das Frontmatter beschädigt -> stoppen.

## Scope

**In:**
- `agent/thot.md` — Prompt-Body vollständig Englisch, inklusive Plan-Template,
  `## Execution rules` und `## Stop Rules`
- `agent/imhotep.md` — Prompt-Body vollständig Englisch
- `command/start-work.md` — Body vollständig Englisch
- Neue Regel in beiden Agents: Antwortsprache folgt der Sprache des Nutzers
- Zweisprachige Trigger-Wort-Akzeptanz am Review-Gate (`weiter` / `continue`)
- `README.md` — kurzer Hinweis-Abschnitt zur Sprach-Trennung

**Out:**
- YAML-Frontmatter aller drei Dateien (bereits englisch, bleibt unverändert)
- `install.sh` — wird nicht geöffnet und nicht bearbeitet
- Bestehende Dateien unter `.plans/` — werden nicht übersetzt
- Der `caveman`-Skill und andere Dateien unter `~/.config/opencode/`
- Jede Form von git-Nutzung, auch lesend

**Must-NOT-Have:**
- Keine inhaltliche Änderung an Regeln, Phasen, Filtern oder Stop Rules. Die
  Übersetzung ist bedeutungserhaltend, nicht bedeutungsverbessernd.
- Keine neuen Abschnitte in den Agent-Dateien außer `## Output language`.
- Keine Änderung an `permission:`-Blöcken, `model:`, `temperature:`, `mode:`.
- Keine Umbenennung von Agents, Dateien, Slugs oder des Kommandos.
- Keine Straffung, Kürzung oder "Verbesserung" beim Übersetzen. Wer einen Absatz
  überflüssig findet: Notiz in `## Findings`, nicht löschen.
- Keine Umstellung auf ein anderes Modell oder einen anderen Provider.
- Kein `git init`, kein Commit, kein Anlegen einer Baseline-Kopie außerhalb des Repos.
- Keine Installation von `rg`, `fd` oder anderen Tools.

## Findings

### Umgebung
- `git log --oneline -3` -> `fatal: Ihr aktueller Branch 'master' hat noch keine
  Commits.` Repo ist initialisiert, aber leer. Alle Dateien sind untracked (`??`).
- `which rg fd` -> keine Treffer. `which grep` -> `/usr/bin/grep`, GNU grep 3.11.
- Repo enthält keine Test-Suite, kein `package.json`, keinen Linter.

### Aktueller Stand von `agent/thot.md` (252 Zeilen)
- Ein vorheriger Ausführungsversuch hat die Prosa-Abschnitte bereits übersetzt.
  Todo 1 ist auf der Platte **weitgehend erledigt** und deshalb idempotent formuliert.
- `agent/thot.md:1-24` — Frontmatter, unverändert. `model: github-copilot/claude-opus-5`
  in Zeile 4, `permission.edit` mit `".plans/**": allow` in Zeile 9.
- Englisch bereits: `# Thot — Planning Consultant` (Z. 26), `## Plan mode is sticky`
  (Z. 36), `## Mandatory opening` (Z. 42), `## Phase 1 — Ground: explore before asking`
  (Z. 58), `### Estimate size` (Z. 74), `## Phase 2 — Intent routing` (Z. 81),
  `## Two filters — before EVERY question, in this order` (Z. 101),
  `## Phase 3 — Approval gate (DO NOT SKIP)` (Z. 116),
  `## Phase 4 — Write plan (only after approval)` (Z. 135),
  `### Task-line format` (Z. 148), `### Plan template` (Z. 165).
- Noch deutsch: Zeilen 175, 181, 183-184, 187 (Template-`## Execution rules`),
  201, 205, 212, 223 (Template-Prosa), 230-232 (Wörtlich-Kopier-Anweisung),
  234-240 (`### Selbstprüfung vor der Übergabe`), 244-252 (`## Stop Rules`).
- `grep -c '^## ' agent/thot.md` -> `16`. Davon 8 außerhalb des Fences und 8 innerhalb
  des `~~~markdown`-Blocks. Der Zähler unterscheidet nicht — das ist der erwartete Wert.
- `grep -c '^~~~' agent/thot.md` -> `2`.
- **Lücke im vorherigen Plan:** `## Stop Rules` (Z. 242-252) war keinem Todo zugeordnet.
  Jetzt Teil von Todo 2.

### `agent/imhotep.md` (129 Zeilen)
- `agent/imhotep.md:1-20` — Frontmatter, `grep -c 'deny' agent/imhotep.md` -> `11`.
- `grep -c '^## ' agent/imhotep.md` -> `8`.
- Body vollständig deutsch, unverändert gegenüber dem Ausgangszustand.
- `agent/imhotep.md:24-37` — "ERSTE AKTION, IMMER": `skill(name="caveman")` plus
  Marker `caveman: on`.
- `agent/imhotep.md:60` — `Erst nach ausdrücklichem "weiter"`. Trigger-Wort.
- `agent/imhotep.md:73` — Gate-Optionen `Weiter mit Todo N+1` / `Nacharbeiten` / `Stop`.
- `agent/imhotep.md:121-122` — Konfliktregel: die strengere Regel gewinnt.

### `command/start-work.md` (23 Zeilen)
- Zeilen 1-4 Frontmatter mit `agent: imhotep`, Body 6-23 deutsch, nutzt `$1`.
- Zeile 8 lädt den `caveman`-Skill redundant zu `agent/imhotep.md:30`. Beabsichtigt.

### `README.md`
- Vollständig englisch. `grep -c '^## ' README.md` -> `16`.
- Enthält `## Prerequisites` mit Skill- und MCP-Tabelle sowie einen CLI-Abschnitt,
  der `rg` und `fd` erwähnt. Kein Abschnitt zur Prompt- vs. Output-Sprache.

## Decisions

- **QA ohne git** — das Repo hat keine Commits, jeder Diff ist leer. Frontmatter-
  Integrität wird stattdessen über positive `grep`-Assertions auf die kritischen
  Zeilen geprüft. Verworfen: `git init` plus Initial-Commit nur für die Verifikation,
  weil das eine Repo-Entscheidung des Nutzers ist und nicht in diesen Plan gehört.
  Verworfen: Baseline-Kopie nach `/tmp`, weil `agent/thot.md` bereits teilübersetzt
  ist und die Baseline damit wertlos wäre.
- **QA über `grep` statt `rg`** — `rg` ist nicht installiert. GNU grep 3.11 ist da und
  kann alles Nötige. Verworfen: `rg` nachinstallieren, weil Toolinstallation nicht
  Teil dieser Aufgabe ist.
- **Todo 1 idempotent formuliert** — die Prosa ist auf der Platte schon übersetzt.
  Das Todo prüft und ergänzt, statt blind neu zu schreiben. Verworfen: Todo streichen,
  weil dann niemand das Ergebnis verifiziert. Verworfen: Datei zurücksetzen, weil das
  ohne git nicht möglich ist.
- **`## Stop Rules` in Todo 2 aufgenommen** — Lücke der vorherigen Planversion.
- **Prompt-Body Englisch, Antwortsprache dynamisch** — Instruction-Compliance und
  Token-Budget gewinnen, ohne dass der Nutzer englische Gate-Reports lesen muss.
  Verworfen: Antworten ebenfalls Englisch, weil der Nutzer deutsch arbeitet.
- **Frontmatter bleibt unverändert** — die Permissions sind die einzige harte
  Absicherung im Setup. Verworfen: "bei der Gelegenheit aufräumen".
- **Trigger-Wörter zweisprachig** — `weiter`, `continue`, `ok`, `go` gelten als
  Fortsetzung, `nacharbeiten`/`rework` und `stop` analog.
- **Plan-Template wird mit übersetzt** — künftige Pläne entstehen auf Englisch.
- **Bestehende Plandateien bleiben deutsch** — inklusive dieser Datei. Sie dient in
  der QA zusätzlich als Positivprobe für den Umlaut-Detektor.
- **README-Hinweis** — die Sprach-Trennung ist eine bewusste Design-Entscheidung und
  gehört dokumentiert, sonst dreht sie beim nächsten Edit jemand zurück.

## Todos

- [x] 1. `agent/thot.md`: Prosa-Abschnitte auf Englisch verifizieren und vervollständigen
      Files:      agent/thot.md
      Steps:      1. Frontmatter (Zeilen 1-24) nicht anfassen.
                  2. Den Bereich vom Titel `# Thot — Planning Consultant` bis
                     einschliesslich `### Plan template` prüfen. Er ist laut Findings
                     bereits übersetzt — nur nachbessern, was noch deutsch ist.
                     Nichts umformulieren, was schon englisch ist.
                  3. Betroffene Abschnitte: Titel, Intro, `## Plan mode is sticky`,
                     `## Mandatory opening`, `## Phase 1`, `### Estimate size`,
                     `## Phase 2`, `## Two filters`, `## Phase 3`, `## Phase 4`,
                     `### Task-line format`, `### Plan template`.
                  4. `THOT: PLAN MODE` exakt beibehalten.
                  5. Task-Zeilen-Format `- [ ] N. <title>` / `- [ ] F<n>. <title>` und
                     die Aussage "column 0" in der Bedeutung unverändert lassen.
                  6. Fachbegriffe nicht ersetzen: CLEAR, UNCLEAR, owner decision,
                     decision-complete, Must-NOT-Have, approval gate, retrieval budget,
                     `file:line`, Context7 MCP, `resolve-library-id`, `query-docs`,
                     `task(subagent_type="explore", ...)`, `question`.
                  7. Abschnittsanzahl und -reihenfolge unverändert lassen.
      Acceptance: Zwischen dem Titel und `### Plan template` steht kein deutscher Text
                  mehr. Der `~~~markdown`-Block darf in diesem Todo noch deutsch sein.
      QA:         happy: `grep -c '^## ' agent/thot.md` -> `16`
                  failure: `grep -c '^model: github-copilot/claude-opus-5$' agent/thot.md` -> `1`; anderer Wert bedeutet beschädigtes Frontmatter -> stoppen
      Commit (Vorschlag): refactor(thot): translate prose sections to english

- [x] 2. `agent/thot.md`: Plan-Template, `## Execution rules` und `## Stop Rules` auf Englisch
      Files:      agent/thot.md
      Steps:      1. Den `~~~markdown`-Block übersetzen.
                  2. `## Execution rules (verbindlich für den ausführenden Agent)`
                     -> `## Execution rules (binding for the executing agent)`;
                     die fünf nummerierten Regeln inhaltsgleich übersetzen.
                  3. Regel 3 im Block: Trigger-Wort als `"weiter" / "continue"`
                     formulieren, damit beide akzeptiert werden.
                  4. `Commit (Vorschlag):` -> `Commit (suggested):`.
                  5. Labels `**In:**` / `**Out:**` / `**Must-NOT-Have:**` und die
                     Feldnamen `Files:` / `Steps:` / `Acceptance:` / `QA:` sowie die
                     Marker `happy:` / `failure:` unverändert lassen.
                  6. `pfad/datei.ts:42` -> `path/file.ts:42`, `pfad/a.ts` -> `path/a.ts`,
                     `pfad/b.ts` -> `path/b.ts`.
                  7. Beispielzeilen `- [ ] 1.`, `- [ ] 2.`, `- [ ] F1.`, `- [ ] F2.`,
                     `- [ ] F3.` im Format unverändert lassen.
                  8. Die Sätze nach dem Block übersetzen: die Wörtlich-Kopier-Anweisung
                     und `### Selbstprüfung vor der Übergabe` -> `### Self-check before handoff`.
                  9. `## Stop Rules` übersetzen, inklusive der Schlusszeile
                     `**Du beginnst niemals selbst mit der Ausführung.**`. Die Überschrift
                     `## Stop Rules` bleibt wörtlich stehen.
                  10. Der Hinweis `/start-work <slug>` bleibt exakt.
      Acceptance: `grep -n '[äöüÄÖÜß]' agent/thot.md` gibt nichts aus.
                  `grep -nwE 'der|die|das|und|nicht|wird|nach|jedem|kein|keine|Nutzer|Datei|Regeln|Abschnitt|Sprache|Befehl' agent/thot.md` gibt nichts aus.
                  Die Überschriften im Fence stehen weiterhin in der Reihenfolge
                  `## TL;DR`, `## Execution rules`, `## Scope`, `## Findings`,
                  `## Decisions`, `## Todos`, `## Final verification`, `## Success criteria`.
      QA:         happy: `grep -c '^~~~' agent/thot.md` -> `2` und `grep -c '^- \[ \] F1\.' agent/thot.md` -> `1`
                  failure: `grep -c '[äöüÄÖÜß]' .plans/english-agent-prompts.md` -> Wert grösser `0`; ergibt der Befehl `0`, ist der Umlaut-Detektor kaputt und alle Sprach-Checks sind wertlos -> stoppen
      Commit (Vorschlag): refactor(thot): translate plan template, execution and stop rules

- [x] 3. `agent/thot.md`: Output-Sprach-Regel ergänzen
      Files:      agent/thot.md
      Steps:      1. Nach dem Intro-Absatz und vor `## Plan mode is sticky` einen neuen
                     Abschnitt `## Output language` einfügen.
                  2. Inhalt: Antworten und Plandateien folgen der Sprache des Nutzers;
                     Standard ist die Sprache seiner letzten Nachricht. Diese
                     Instruktionen sind Englisch und bleiben Englisch.
                  3. Exakt beibehalten, unabhängig von der Antwortsprache: Code,
                     Befehle, Pfade, `file:line`-Referenzen, Bezeichner,
                     Fehlermeldungen, `THOT: PLAN MODE`, alle Abschnittsnamen des
                     Plan-Templates und alle Task-Zeilen-Präfixe.
                  4. Maximal 6 Zeilen. Keinen weiteren Abschnitt hinzufügen.
      Acceptance: `grep -c '^## Output language$' agent/thot.md` -> `1`.
                  Der Abschnitt steht vor `## Plan mode is sticky`.
      QA:         happy: `grep -n '^## Output language$\|^## Plan mode is sticky$' agent/thot.md` -> `## Output language` hat die kleinere Zeilennummer
                  failure: `grep -c '^## ' agent/thot.md` -> `17`; jeder andere Wert bedeutet mehr oder weniger als einen neuen Abschnitt -> nacharbeiten
      Commit (Vorschlag): feat(thot): add explicit output language rule

- [x] 4. `agent/imhotep.md` auf Englisch, mit zweisprachigen Trigger-Wörtern
      Files:      agent/imhotep.md
      Steps:      1. Frontmatter (Zeilen 1-20) mit allen `deny`-Regeln nicht anfassen.
                  2. Body übersetzen: "ERSTE AKTION, IMMER" -> "FIRST ACTION, ALWAYS",
                     "Ablauf" -> "Flow", "Pro Todo" -> "Per todo", "Das Review-Gate"
                     -> "The review gate", "Das Gate ist nicht verhandelbar",
                     "Keine Commits", "Scope-Guard", "Eskalation statt Improvisation",
                     "Vorrang bei Konflikten", "Stop Rules".
                  3. `skill(name="caveman")` und den Marker `caveman: on` exakt behalten.
                  4. Alle git- und gh-Befehlsnamen exakt behalten.
                  5. Trigger-Wörter zweisprachig festschreiben: Fortsetzung bei
                     `weiter` / `continue` / `ok` / `go`; Nacharbeit bei
                     `nacharbeiten` / `rework`; Abbruch bei `stop`.
                  6. Gate-Optionen als `Continue with todo N+1` / `Rework` / `Stop`.
                  7. Abschnitt `## Output language` mit demselben Inhalt wie in Todo 3
                     ergänzen, direkt nach dem caveman-Block. Zusatz: Commit-Nachrichten
                     sind immer Englisch.
                  8. `.plans/<slug>.md`, `todowrite`, `question`, `## Todos`,
                     `## Final verification`, `## Findings`, `Must-NOT-Have`, `- [ ]`
                     und `- [x]` exakt behalten.
      Acceptance: `grep -n '[äöüÄÖÜß]' agent/imhotep.md` gibt nichts aus.
                  `grep -nwE 'der|die|das|und|nicht|wird|nach|jedem|kein|keine|Nutzer|Datei|Regeln|Abschnitt|Befehl' agent/imhotep.md` gibt nichts aus.
                  `grep -n 'weiter' agent/imhotep.md` trifft ausschliesslich die
                  Trigger-Wort-Liste.
      QA:         happy: `grep -c 'deny' agent/imhotep.md` -> `11` und `grep -c '^## Output language$' agent/imhotep.md` -> `1`
                  failure: `grep -cF 'skill(name="caveman")' agent/imhotep.md` -> Wert grösser `0`; ergibt der Befehl `0`, wurde die Pflicht-Aktion zerstört -> stoppen
      Commit (Vorschlag): refactor(imhotep): translate prompt to english

- [x] 5. `command/start-work.md` auf Englisch
      Files:      command/start-work.md
      Steps:      1. Frontmatter (Zeilen 1-4) nicht anfassen.
                  2. Body (Zeilen 6-23) übersetzen.
                  3. `$1`, `.plans/$1.md`, `.plans/`, `caveman`, `todowrite`,
                     `question`, `## Execution rules`, `## Todos`, `## Findings`,
                     `Must-NOT-Have` exakt behalten.
                  4. Die drei Erinnerungsregeln am Ende inhaltsgleich übersetzen und
                     mit den Formulierungen aus `agent/imhotep.md` abgleichen.
                  5. Das Trigger-Wort dort ebenfalls als `"weiter" / "continue"` schreiben.
      Acceptance: `grep -n '[äöüÄÖÜß]' command/start-work.md` gibt nichts aus.
                  `grep -c '\$1' command/start-work.md` -> Wert grösser `0`.
      QA:         happy: `grep -c '^agent: imhotep$' command/start-work.md` -> `1`
                  failure: `grep -c 'agent/thot.md' command/start-work.md` -> `0`; jeder andere Wert bedeutet eine falsche Referenz -> nacharbeiten
      Commit (Vorschlag): refactor(start-work): translate command body to english

- [x] 6. README um Sprach-Hinweis ergänzen und Gesamt-Konsistenz prüfen
      Files:      README.md, agent/thot.md, agent/imhotep.md, command/start-work.md
      Steps:      1. In `README.md` nach dem Abschnitt `## imhotep — Worker` einen
                     Abschnitt `## Language` einfügen.
                  2. Inhalt: Prompts und Plandateien sind Englisch — bessere
                     Instruction-Compliance, geringeres Token-Budget, späterer
                     Compaction-Punkt. Antworten an den Nutzer folgen dessen Sprache.
                     Gate-Trigger werden zweisprachig akzeptiert (`weiter` / `continue`).
                  3. Maximal 8 Zeilen, keine Tabelle.
                  4. Im bestehenden CLI-Abschnitt von `README.md` den Hinweis auf `rg`
                     und `fd` um einen Halbsatz ergänzen, dass beide optional sind und
                     `grep` als Fallback genügt. Keine weitere Änderung dort.
                  5. Terminologie über alle vier Dateien abgleichen: "todo",
                     "review gate", "owner decision", "scope guard",
                     "final verification" werden überall identisch geschrieben.
                  6. Prüfen, dass `README.md` weiterhin `agent/thot.md`,
                     `agent/imhotep.md` und `command/start-work.md` korrekt referenziert.
      Acceptance: `grep -c '^## Language$' README.md` -> `1`.
                  Die genannten Begriffe sind in allen vier Dateien einheitlich.
      QA:         happy: `grep -c '^## ' README.md` -> `17`
                  failure: `grep -n '[äöüÄÖÜß]' README.md agent/thot.md agent/imhotep.md command/start-work.md` -> nur Treffer in Trigger-Wort-Listen und im `## Language`-Abschnitt; alles andere -> nacharbeiten
      Commit (Vorschlag): docs: document prompt vs output language split

## Final verification

- [ ] F1. Dateiumfang: nur `agent/thot.md`, `agent/imhotep.md`,
      `command/start-work.md` und `README.md` wurden bearbeitet. `install.sh`,
      `.gitignore` und alles unter `.plans/` sind unangetastet. Prüfen über die
      eigene Bearbeitungsliste der Session, nicht über git.
- [ ] F2. Frontmatter unversehrt — alle vier Assertions müssen zutreffen:
      `grep -c '^model: github-copilot/claude-opus-5$' agent/thot.md` -> `1`;
      `grep -cF '".plans/**": allow' agent/thot.md` -> `1`;
      `grep -c 'deny' agent/imhotep.md` -> `11`;
      `grep -c '^agent: imhotep$' command/start-work.md` -> `1`
- [ ] F3. Sprach-Check: `grep -n '[äöüÄÖÜß]' agent/thot.md agent/imhotep.md command/start-work.md README.md`
      liefert ausschliesslich Treffer in den dokumentierten Trigger-Wort-Listen und im
      `## Language`-Abschnitt der README. Gegenprobe, dass der Detektor funktioniert:
      `grep -c '[äöüÄÖÜß]' .plans/english-agent-prompts.md` -> Wert grösser `0`
- [ ] F4. Scope-Treue: keine Regel inhaltlich geändert, keine Datei umbenannt, kein
      git-Befehl ausgeführt, kein Tool installiert, nichts aus `Must-NOT-Have` gebaut

## Success criteria

- `agent/thot.md`, `agent/imhotep.md` und `command/start-work.md` sind vollständig
  englisch, abgesehen von den bewusst zweisprachigen Trigger-Wörtern.
- Alle YAML-Frontmatter-Blöcke sind unverändert; die vier F2-Assertions treffen zu.
- Beide Agents haben einen `## Output language`-Abschnitt; Antworten folgen der
  Sprache des Nutzers, Commit-Nachrichten sind Englisch.
- Das Plan-Template erzeugt künftige Pläne auf Englisch, mit unveränderten
  Abschnittsnamen und unverändertem Task-Zeilen-Format.
- `README.md` erklärt die Trennung von Prompt- und Antwortsprache und markiert
  `rg`/`fd` als optional.
- Kein QA-Schritt braucht `git`, `rg` oder `fd`.
- Kein Regelinhalt hat sich geändert — die Änderungen sind reine Übersetzung plus
  die drei neuen Abschnitte.
