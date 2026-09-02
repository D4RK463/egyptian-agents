# agent-switch-guard — Work Plan

## TL;DR
**Was du bekommst:** Ein Identitäts-Guard in `agent/imhotep.md` und
`command/start-work.md`, der abbricht statt still unter thot weiterzulaufen,
plus korrigierte README-Doku zum Agent-Wechsel.
**Warum:** `agent:` im Command-Frontmatter wechselt keinen `primary` Agent. Der
Fehler war dreimal unsichtbar, bis eine Permission zufällig griff.
**Was es NICHT tut:** Kein Wrapper-Skript, kein `subtask:true`, keine Änderung
an `install.sh`, kein Mechanismus-Umbau.
**Aufwand:** 4 Todos.
**Risiko:** Niedrig — reine Prompt- und Doku-Änderung. Der Guard ist eine weiche
Regel; er macht den Fehler sichtbar, verhindert ihn nicht.

## Execution rules (binding for the executing agent)

1. Load the skill first: `skill(name="caveman")`. Do not work without the skill loaded.
   Every user-facing output is caveman-terse. Code, commands, error messages, and
   identifiers stay exact.
2. No commits. `git commit`, `push`, `merge`, `rebase`, `reset`, `tag` are forbidden.
   Commit suggestions are emitted only as a copyable command.
3. Review gate after EVERY todo: implement -> run QA -> stop -> call `question`
   (changes, QA evidence, commit suggestion, options continue/rework/stop).
   Only after an explicit "weiter" / "continue" is `- [x]` set and the next todo started.
   Stopping is correct behavior, not laziness. Never bundle two todos in one gate.
4. `Must-NOT-Have` is binding. Extra ideas go as a note into `## Findings`, not into code.
5. Plan wrong or reality differs: stop, report, hand back to thot. Do not replan yourself.

## Umgebungsvorgaben für die QA

Diese Regeln gelten für ALLE QA- und Acceptance-Befehle in diesem Plan:

- **Kein `git`.** Das Repo hat null Commits. `git diff` und `git status` liefern
  keine verwertbare Evidenz und werden nicht verwendet.
- **Kein `rg`, kein `fd`.** Beide sind nicht installiert. Jede Suche läuft über
  GNU `grep` 3.11.
- Alle Befehle werden aus dem Repo-Root ausgeführt.
- Ein Befehl gilt als "gibt nichts aus", wenn `grep` keine Zeile ausgibt (Exit-Code 1).
- **Ausnahme zur Scope-Prüfung:** Das Setzen von `- [x]` in dieser Plandatei ist
  durch die Execution rules vorgeschrieben und gilt nicht als Scope-Verletzung.

## Scope

**In:**
- `agent/imhotep.md` — Identitäts-Guard als Teil der Pflicht-Eröffnung
- `command/start-work.md` — Identitäts-Guard als Schritt 0
- `README.md` — Wechsel-Wege dokumentieren, `## Workflow` korrigieren,
  Enforcement-Aussagen präzisieren

**Out:**
- `agent/thot.md` — unverändert
- `install.sh` — wird nicht geöffnet und nicht bearbeitet
- YAML-Frontmatter aller Dateien
- Ein Wrapper-Skript `start-work.sh` — vom Nutzer ausdrücklich abgelehnt
- `subtask: true` — verworfen, Gate-Kompatibilität ungeprüft
- Jede Form von git-Nutzung, auch lesend

**Must-NOT-Have:**
- Kein `subtask: true` in `command/start-work.md`
- Keine neue Datei im Repo, kein neues Skript
- Keine Änderung an `permission:`, `model:`, `temperature:`, `mode:`, `agent:`
- Kein Entfernen von `agent: imhotep` aus `command/start-work.md` — die Zeile
  dokumentiert weiterhin die Absicht
- Keine inhaltliche Änderung an Gate-, Commit- oder Scope-Regeln
- Keine deutschen Prompt-Texte; die zweisprachigen Trigger-Wortlisten bleiben
- Keine Installation von Tools, kein `git init`

## Findings

### Ursache
- `command/start-work.md:3` — `agent: imhotep`. Wirkungslos, weil
  `agent/imhotep.md:3` `mode: primary` setzt. Laut opencode-Doku löst `agent:`
  nur bei `mode: subagent` eine Invocation aus; sonst landet der Prompt im
  aktuell aktiven Agent.
- `opencode agent list` -> `imhotep (primary)` und `thot (primary)`. Beide
  korrekt registriert, beide primary.
- `opencode --help` -> `--agent` und `--prompt` existieren in Version 1.17.18.
- Keybinds laut Doku: `agent_cycle` = `tab`, `agent_list` = `<leader>a`,
  Leader ist `ctrl+x`.
- Es gibt keine Konfigoption, die einen primary Agent aus einem Command heraus
  wechselt.

### Zieldateien
- `agent/imhotep.md:22` — `# Imhotep — Plan Executor`. Der Agent kennt seine
  Identität aus dem Prompt.
- `agent/imhotep.md:24-37` — `## FIRST ACTION, ALWAYS`, lädt `caveman`, setzt den
  Marker `caveman: on`. Natürlicher Ort für den Guard.
- `grep -c '^## ' agent/imhotep.md` -> `9`.
- `grep -c 'deny' agent/imhotep.md` -> `11`.
- `command/start-work.md:6-15` — nummerierte Schritte 1-5. Der Guard wird der
  neue erste Schritt.
- `command/start-work.md:17-23` — drei Erinnerungsregeln, bleiben inhaltlich.
- `README.md:101-105` — `## Workflow`-Codeblock nennt nur `/start-work <slug>`,
  ohne Wechsel-Schritt. Ursache der falschen Erwartung.
- `README.md:120-121` — "thot *cannot* change production code." Gilt nur bei
  aktivem thot.
- `README.md:168` — Tabellenzeile behauptet `permission.edit` und
  `permission.bash` seien **hart**. Gleiche fehlende Vorbedingung.
- `README.md:137` — `## Language` existiert bereits; der neue Abschnitt kommt
  danach.
- `grep -c '^## ' README.md` -> `17` vor diesem Plan.

## Decisions

- **Guard statt Mechanismus-Umbau** — opencode bietet keinen Command-getriebenen
  Wechsel für primary Agents. Verworfen: `subtask: true`, weil imhotep dann in
  einer Child-Session liefe und unbestätigt ist, ob `question` pro Todo den
  Nutzer interaktiv erreicht. Das Review-Gate ist der Kern des Workflows und
  wird nicht auf eine ungeprüfte Annahme gesetzt. Verworfen: `mode: all`, weil
  es dieselbe Child-Session-Frage aufwirft.
- **Kein Wrapper-Skript** — vom Nutzer entschieden. Neues Artefakt plus
  `install.sh`-Änderung ohne funktionalen Gewinn gegenüber `ctrl+x` dann `a`.
- **`agent: imhotep` bleibt stehen** — schadet nicht, dokumentiert die Absicht
  und wird korrekt, sobald opencode den Wechsel unterstützt.
- **Guard an zwei Stellen** — `agent/imhotep.md` greift bei jedem Einstieg,
  `command/start-work.md` auch dann, wenn der Command aus einem fremden Agent
  aufgerufen wird. Die Redundanz ist der Punkt, nicht ein Versehen.
- **README-Enforcement-Aussagen werden präzisiert, nicht umgeschrieben** — die
  Aussagen sind nicht falsch, ihnen fehlt die Vorbedingung.
- **4 Todos statt der üblichen 5-8** — die Aufgabe ist klein. Padding würde nur
  zusätzliche Gates erzeugen.

## Todos

- [x] 1. `agent/imhotep.md`: Identitäts-Guard in die Pflicht-Eröffnung
      Files:      agent/imhotep.md
      Steps:      1. Frontmatter (Zeilen 1-20) nicht anfassen.
                  2. In `## FIRST ACTION, ALWAYS` vor dem `skill(name="caveman")`-Aufruf
                     einen Guard-Schritt ergänzen: prüfen, ob dieser Agent Imhotep ist.
                     Wenn nein: sofort stoppen, keine Plandatei lesen, nichts schreiben.
                  3. Abbruchtext festlegen: der Nutzer soll mit `tab` oder `ctrl+x`
                     dann `a` auf imhotep wechseln, alternativ `opencode --agent imhotep`
                     starten.
                  4. Begründung in einem Satz: ein anderer Agent hat andere Permissions,
                     die No-Commit- und Edit-Grenzen gelten dann nicht.
                  5. Maximal 8 Zeilen. Keinen neuen `##`-Abschnitt anlegen.
                  6. Englisch schreiben. `skill(name="caveman")` und `caveman: on`
                     exakt behalten.
      Acceptance: `## FIRST ACTION, ALWAYS` enthält den Guard vor dem Skill-Aufruf.
                  Die Abschnittsanzahl ist unverändert.
      QA:         happy: `grep -c '^## ' agent/imhotep.md` -> `9`
                  failure: `grep -cF 'skill(name="caveman")' agent/imhotep.md` -> Wert grösser `0`; ergibt der Befehl `0`, wurde die Pflicht-Aktion zerstört -> stoppen
      Commit (suggested): feat(imhotep): abort when running under wrong agent

- [x] 2. `command/start-work.md`: Guard als erster Schritt
      Files:      command/start-work.md
      Steps:      1. Frontmatter (Zeilen 1-4) nicht anfassen. `agent: imhotep` bleibt.
                  2. Vor dem bisherigen Schritt 1 einen neuen Schritt einfügen:
                     Identität prüfen, bei Nichtübereinstimmung stoppen und den
                     Wechsel-Weg nennen.
                  3. Die bestehenden Schritte neu durchnummerieren, sodass die Liste
                     lückenlos von 1 aufsteigt.
                  4. Die drei Erinnerungsregeln am Ende inhaltlich unverändert lassen.
                  5. `$1`, `.plans/$1.md`, `.plans/`, `caveman`, `todowrite`,
                     `question`, `## Execution rules`, `## Todos`, `## Findings`,
                     `Must-NOT-Have` exakt behalten.
                  6. Englisch schreiben. Trigger-Wortliste `"weiter" / "continue"`
                     unverändert lassen.
      Acceptance: Der Guard ist der erste nummerierte Schritt. Die Nummerierung ist
                  lückenlos und beginnt bei 1.
      QA:         happy: `grep -c '^agent: imhotep$' command/start-work.md` -> `1`
                  failure: `grep -c '\$1' command/start-work.md` -> Wert grösser `0`; ergibt der Befehl `0`, wurde der Slug-Platzhalter zerstört -> stoppen
      Commit (suggested): feat(start-work): guard against wrong agent

- [x] 3. `README.md`: Agent-Wechsel dokumentieren
      Files:      README.md
      Steps:      1. Den `## Workflow`-Codeblock um den Wechsel-Schritt vor
                     `/start-work <slug>` ergänzen.
                  2. Nach dem Abschnitt `## Language` einen Abschnitt
                     `## Switching agents` einfügen.
                  3. Inhalt: `agent:` im Command-Frontmatter wechselt keinen `primary`
                     Agent — der Prompt landet im aktuell aktiven Agent. Wechsel-Wege
                     als Tabelle: `tab` (`agent_cycle`), `ctrl+x` dann `a`
                     (`agent_list`), `opencode --agent imhotep` für eine neue Session.
                  4. Einen Satz zur Folge: ohne Wechsel läuft `/start-work` mit thots
                     Permissions; der Guard aus Todo 1 und 2 bricht dann ab.
                  5. Maximal 12 Zeilen.
      Acceptance: `grep -c '^## Switching agents$' README.md` -> `1`. Der
                  `## Workflow`-Block nennt den Wechsel-Schritt.
      QA:         happy: `grep -c '^## ' README.md` -> `18`
                  failure: `grep -c '^## Language$' README.md` -> `1`; jeder andere Wert bedeutet, ein bestehender Abschnitt wurde beschädigt -> nacharbeiten
      Commit (suggested): docs: document primary agent switching

- [x] 4. `README.md`: Enforcement-Aussagen präzisieren
      Files:      README.md
      Steps:      1. Vor der Änderung `grep -c '^| ' README.md` ausführen und den Wert
                     notieren. Er dient als Referenz für die QA.
                  2. Die Tabellenzeile zu `permission.edit`, `permission.bash` um die
                     Vorbedingung ergänzen: hart, sofern der passende Agent aktiv ist.
                  3. Die Aussage "thot *cannot* change production code" um denselben
                     Vorbehalt ergänzen.
                  4. Die Tabellenstruktur nicht ändern, nur die betroffene Zelle.
                     Keine weitere Tabellenzeile anfassen.
      Acceptance: Beide Stellen nennen die Vorbedingung. Die Tabelle hat unverändert
                  viele Zeilen.
      QA:         happy: `grep -c '^| ' README.md` -> derselbe Wert wie in Schritt 1 gemessen; beide Werte im Gate zeigen
                  failure: `grep -c 'hard' README.md` -> Wert grösser `0`; ergibt der Befehl `0`, wurde die Enforcement-Tabelle zerstört -> stoppen
      Commit (suggested): docs: qualify enforcement claims with active agent

## Final verification

- [x] F1. Dateiumfang: nur `agent/imhotep.md`, `command/start-work.md` und
      `README.md` wurden bearbeitet. `agent/thot.md`, `install.sh` und `.gitignore`
      sind unangetastet. Das Setzen von `- [x]` in dieser Plandatei ist erlaubt und
      zählt nicht als Verletzung. Prüfen über die eigene Bearbeitungsliste der
      Session, nicht über git.
- [x] F2. Frontmatter unversehrt — alle drei Assertions müssen zutreffen:
      `grep -c 'deny' agent/imhotep.md` -> `11`;
      `grep -c '^mode: primary$' agent/imhotep.md` -> `1`;
      `grep -c '^agent: imhotep$' command/start-work.md` -> `1`
- [x] F3. Sprach-Check: `grep -n '[äöüÄÖÜß]' agent/imhotep.md command/start-work.md README.md`
      liefert ausschliesslich Treffer in den dokumentierten Trigger-Wortlisten.
      Gegenprobe, dass der Detektor funktioniert:
      `grep -c '[äöüÄÖÜß]' .plans/agent-switch-guard.md` -> Wert grösser `0`
- [x] F4. Scope-Treue: `grep -c 'subtask' command/start-work.md` -> `0`; keine neue
      Datei angelegt, `install.sh` unverändert, kein git-Befehl ausgeführt, nichts
      aus `Must-NOT-Have` gebaut

## Success criteria

- Läuft `/start-work` unter einem anderen Agent als imhotep, bricht die Ausführung
  im ersten Schritt ab und nennt den Wechsel-Weg.
- `README.md` erklärt, warum `agent:` im Command nicht genügt, und listet `tab`,
  `ctrl+x` dann `a` sowie `opencode --agent imhotep`.
- Der `## Workflow`-Block zeigt den Wechsel-Schritt vor `/start-work`.
- Die Enforcement-Aussagen in `README.md` nennen ihre Vorbedingung.
- Kein neues Artefakt, `install.sh` unverändert, `agent: imhotep` bleibt im
  Frontmatter von `command/start-work.md`.
- Kein QA-Schritt braucht `git`, `rg` oder `fd`.
