# thot-hardening-2 — Vorschlag aus der Retrospektive „eSIM-Business-Tests"

Begleitdokument zu `.plans/thot.md.proposed`. Nachfolger von
`.plans/thot-hardening.md`; dessen vier Ergänzungen sind in `agent/thot.md`
bereits enthalten und werden hier nicht angefasst.

## Warum das nicht direkt angewandt wurde

Unverändert wie beim Vorgänger: Thots `edit`-Permission erlaubt nur `.plans/**`
(`agent/thot.md:8-11`). Der Vorschlag liegt deshalb als vollständige Datei hier
und wird per Kopierbefehl übernommen.

## Anwenden

`install.sh:44` symlinkt das ganze `agent/`-Verzeichnis nach
`~/.config/opencode/agent`. Datei im Repo ersetzen genügt.

```bash
cd /home/kpoepperling/IdeaProjects/personal/agents
diff -u agent/thot.md .plans/thot.md.proposed        # vorher prüfen
cp .plans/thot.md.proposed agent/thot.md
rm .plans/thot.md.proposed
```

Danach **opencode neu starten** — die Konfiguration wird nur beim Start geladen.

## Was sich ändert

Vier Einfügungen, 335 → 377 Zeilen. Frontmatter, Modell und Permissions bleiben
unverändert. Keine bestehende Regel wurde entfernt oder abgeschwächt.

| # | Ergänzung | Zielabschnitt | Adressiert |
|---|---|---|---|
| 1 | „Explain an existing construct before the plan removes it" | Phase 1 | `TenantContextHolder.withTenantContext` im bestehenden await-Block als „Kopplung" entfernt, ohne je zu erklären, warum es dort stand |
| 2 | „When the plan introduces concurrency, name the ambient state it needs" | Phase 1 | Awaitility pollt auf eigenem Thread; `TenantContextHolder` ist ein reines `ThreadLocal` — Halter-Implementierung wurde erst nach dem Fehlschlag gelesen |
| 3 | „Scope fidelity needs a reference point" | Phase 4 | F4 verlangte einen sauberen Working Tree, obwohl in Phase 1 selbst 94 schmutzige Einträge beobachtet wurden |
| 4 | „Cite the producer, not the type" + „Dry-run the verification commands you are allowed to run" | Self-check | `inProgress` aus Enum-Mitgliedschaft erschlossen statt aus einer schreibenden Codestelle; F4 nie gegen die Realität durchgespielt |

## Der gemeinsame Nenner

Alle drei Blockaden dieser Session lagen in der **Verifikationsschicht**, nicht
im Entwurf. Die Grundidee — Business-Narrativ, Assertions ausschliesslich über
die öffentliche API — hat durch alle vier Todos gehalten. Kaputt war jedes Mal:
woran erkennen wir, dass es stimmt.

Und in allen drei Fällen lag die widerlegende Evidenz **bereits im Kontext**.
Kein Retrieval-Problem, ein Abgleich-Problem. Der bestehende `Retrieval budget`
(`agent/thot.md:95-97`) optimiert darauf, mit Suchen aufzuhören; nichts erzwang
einen Durchgang, der die Todos gegen die eigenen Findings prüft. Ergänzung 4
schliesst genau diese Lücke, und zwar mit dem billigsten verfügbaren Mittel:
die Prüfbefehle einmal ausführen.

## Die wichtigste Einzeländerung

Der Dry-Run-Absatz. F4 wäre in Sekunden gestorben — `git status --short` stand
auf der Allowlist und wurde in Phase 1 sogar ausgeführt. Die Ausgabe war da, das
Kriterium widersprach ihr, und niemand hat beides nebeneinandergelegt.

Zwei der drei Blockaden waren so vermeidbar (F4 durch Ergänzung 4, `inProgress`
durch „Cite the producer"). Die dritte durch Ergänzung 1.

## Was bewusst nicht geändert wurde

- **Die Permissions.** Explizit entschieden: Die bash-Allowlist bleibt, wie sie
  ist. Erwogen und verworfen wurde, `diff`/`find`/`grep` aufzunehmen, damit das
  Trockenlaufen keine Rückfragen auslöst. Begründung gegen die Erweiterung: der
  teuerste Fehler wäre mit dem bereits erlaubten `git status --short`
  aufgefallen, und `find` kann über `-exec`/`-delete` schreiben — die Grenze
  würde unschärfer, als sie aussieht. Rückfragen sind der günstigere Preis.
- **Die Todo-Obergrenze 5–8.** Vier Todos waren richtig geschnitten. Kein Defekt
  ging auf Zuschnitt zurück.
- **Die `## Execution rules`.** Sie haben erneut gehalten: imhotep hat dreimal
  blockiert und kein einziges Mal improvisiert. Ohne Regel 5 wäre aus dem
  `inProgress`-Fehler still ein `IN_PROGRESS`-Übergang im Produktionscode
  geworden — eine Verhaltensänderung, durch einen Test-Refactoring-Plan
  hereingeschmuggelt.

## Erledigt: der Konfigurationswiderspruch aus thot-hardening.md

`.plans/thot-hardening.md:74-91` notierte, dass das `question`-Tool Thot nicht
zur Verfügung stand, obwohl `agent/thot.md:139` seine Benutzung vorschreibt.

**In dieser Umgebung existiert das Werkzeug.** Der Widerspruch ist damit keiner
mehr und die Notiz erledigt.

Offen bleibt allerdings ein Befund über das Verhalten, nicht über die Config:
Thot hat in dieser Session die erste Frage trotzdem als Prosa gestellt und das
Werkzeug erst bei der zweiten benutzt. Die Regel steht seit jeher korrekt in der
Config — sie wurde nicht befolgt. Das ist durch keine Textänderung zu beheben
und deshalb hier nur festgehalten.

## Produktbefund am Rande

Aus der Ausführung stammt ein Befund, der nichts mit Thot zu tun hat und in
`bss-modulith` liegt: Order-Items ohne Erfüllung bleiben dauerhaft auf
`acknowledged` — kein Timeout, kein Owner, keine Progression
(`ProductOrderItem.kt:30`, `CompleteProductOrderItemService.kt:22-23`). Steht in
den Findings von `.plans/esim-business-tests-rewrite.md` und wartet dort auf eine
eigene Entscheidung.
