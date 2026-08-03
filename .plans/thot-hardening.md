# thot-hardening — Vorschlag aus der TPS-418-Retrospektive

Begleitdokument zu `.plans/thot.md.proposed`.

## Warum das nicht direkt angewandt wurde

Thots eigene Permissions erlauben `edit` nur unter `.plans/**`:

```yaml
edit:
  "*": deny
  ".plans/**": allow
  "**/.plans/**": allow
```

Der Versuch, `agent/thot.md` zu bearbeiten, wurde folgerichtig blockiert. Das ist
korrektes Verhalten und wurde nicht umgangen. Der Vorschlag liegt deshalb als
vollständige Datei unter `.plans/` und wird per Kopierbefehl übernommen.

## Anwenden

`install.sh` symlinkt das ganze `agent/`-Verzeichnis nach
`~/.config/opencode/agent`. Es genügt daher, die Datei im Repo zu ersetzen —
der Symlink zieht automatisch nach.

```bash
cd /home/kpoepperling/IdeaProjects/personal/agents
diff -u agent/thot.md .plans/thot.md.proposed        # vorher prüfen
cp .plans/thot.md.proposed agent/thot.md
rm .plans/thot.md.proposed
```

Danach **opencode neu starten** — die Konfiguration wird nur beim Start geladen.

## Was sich ändert

Vier Ergänzungen, 264 → 334 Zeilen. Frontmatter, Modell und Permissions bleiben
unverändert. Keine bestehende Regel wurde entfernt oder abgeschwächt.

| # | Ergänzung | Adressiert |
|---|---|---|
| 1 | Phase 1: Framework-Verifikation bindet am härtesten bei Vertrautem; Doku-Widerspruch ist ein Finding; Subagenten-Befunde bei Strukturthemen selbst nachprüfen | `ClientHttpRequestFactorySettings`; unklare Antwortform von `/esims/assignments`; übersehener `inventory-012` |
| 2 | Phase 4: neuer Abschnitt „Enumerate failure per step, not per call" inkl. asymmetrischem Fall (Seiteneffekt erfolgreich, lokaler Schritt gescheitert) | fehlendes Verhalten bei fremdem Provider, Längenüberläufen und HTTP-Erfolg mit lokalem Abschlussfehler |
| 3 | Self-check: Falsifizierbarkeit, referenzielle Integrität, Einmal-Formulierung von Regeln | grüner aber wirkungsloser Persistenztest; Controller-Tests mit Mocks gegen einen RLS-Fehler; `CompensationService` nicht in `Files`; failure-wins-Widerspruch |
| 4 | Neuer Abschnitt „Amending a plan during execution" | sechs Blockaden, bei denen jeweils Symptom statt Ursache naheliegend gewesen wäre |

### Die wichtigste Einzeländerung

Der Falsifizierbarkeits-Absatz im Self-check. Beide teuren Defekte der Story
entstanden nicht dadurch, dass ein Risiko übersehen wurde, sondern dadurch, dass
für ein korrekt erkanntes Risiko eine Prüfung entworfen wurde, die es nicht
auslösen konnte:

- Der Persistenztest zum Spring-Data-JDBC-Verhalten legte keine
  `inventory.product`-Zeile an und konnte deshalb nie rot werden.
- Die Controller-Tests für die Lese-Endpoints mockten die Ports und berührten
  die Datenbank nie — der RLS-Fehler war strukturell unauffindbar.

Die neue Regel verlangt für jedes Acceptance- und QA-Kriterium den konkreten
Umstand, unter dem es rot wäre.

## Was bewusst nicht geändert wurde

- **Die Permissions.** Dass Thot nur unter `.plans/**` schreiben darf, hat in
  dieser Session funktioniert — genau deshalb liegt dieser Vorschlag hier statt
  im Zielpfad.
- **Die Todo-Obergrenze von 5–8.** Todo 4 hatte vier Defekte, war aber richtig
  geschnitten; das Problem war fehlende Fehlerenumeration, nicht die Grösse.
  Ergänzung 2 adressiert das direkt.
- **Die `## Execution rules`.** Sie haben gehalten: imhotep hat sechsmal
  blockiert statt zu improvisieren. Bei „HTTP-Erfolg plus lokaler Fehler" wäre
  die naheliegende Improvisation die schädlichste Variante gewesen.

## Beobachteter Konfigurationswiderspruch

`thot.md` sagt in Phase 2:

> Ask questions through the `question` tool, not as a wall of prose.

Und die `## Execution rules` im Plan-Template verlangen von imhotep:

> Review gate after EVERY todo: implement -> run QA -> stop -> call `question`

Ein Werkzeug namens `question` stand Thot in dieser Session nicht zur Verfügung;
alle Fragen liefen als Prosa. Ob imhotep es hat, wurde nicht geprüft.

Nicht angefasst, weil unklar ist, ob das Werkzeug in einer anderen Umgebung
existiert oder ob die Anweisung ins Leere zeigt. Falls Letzteres: entweder das
Werkzeug bereitstellen oder beide Stellen auf „ask the user directly"
umformulieren — sonst steht in beiden Agenten eine Anweisung, die nicht
ausführbar ist.
