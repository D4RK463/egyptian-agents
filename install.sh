#!/usr/bin/env bash
# Symlinkt thot + horus + imhotep + seshat und die /review-plan, /start-work und
# /start-learning Commands in die globale opencode-Konfiguration. Legt das
# persönliche Seshat-Logbuch an, falls es fehlt. Idempotent. Fasst nichts an, was kein
# Symlink ist.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

fail() { printf 'FEHLER: %s\n' "$1" >&2; exit 1; }
ok()   { printf '  ok    %s\n' "$1"; }
skip() { printf '  skip  %s\n' "$1"; }

link() {
  local src="$1" dst="$2"

  if [ -L "$dst" ]; then
    local cur
    cur="$(readlink -f "$dst" || true)"
    if [ "$cur" = "$(readlink -f "$src")" ]; then
      skip "$dst (zeigt schon hierher)"
      return
    fi
    fail "$dst ist ein Symlink auf '$cur'. Bitte manuell prüfen und entfernen."
  fi

  [ -e "$dst" ] && fail "$dst existiert und ist kein Symlink. Bitte manuell sichern."

  ln -s "$src" "$dst"
  ok "$dst -> $src"
}

[ -d "$CONFIG" ] || fail "$CONFIG existiert nicht. Läuft opencode auf dieser Maschine?"

printf 'Installiere Agents nach %s\n' "$CONFIG"

# Agents: ganzes Verzeichnis, da ~/.config/opencode/agent/ üblicherweise noch fehlt.
link "$REPO/agent" "$CONFIG/agent"

# Commands: nur die einzelne Datei, das Verzeichnis enthält meist schon anderes.
if [ -d "$CONFIG/commands" ]; then
  CMD_DIR="$CONFIG/commands"
elif [ -d "$CONFIG/command" ]; then
  CMD_DIR="$CONFIG/command"
else
  CMD_DIR="$CONFIG/command"
  mkdir -p "$CMD_DIR"
  ok "$CMD_DIR angelegt"
fi
link "$REPO/command/start-work.md" "$CMD_DIR/start-work.md"
link "$REPO/command/review-plan.md" "$CMD_DIR/review-plan.md"
link "$REPO/command/start-learning.md" "$CMD_DIR/start-learning.md"

# Seshat-Logbuch: Kopie statt Symlink, damit persönliche Einträge nie im Repo landen.
SESHAT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/seshat"
mkdir -p "$SESHAT_DIR/solutions"
if [ -e "$SESHAT_DIR/logbook.md" ]; then
  skip "$SESHAT_DIR/logbook.md (existiert schon, bleibt unverändert)"
else
  cp "$REPO/seshat/logbook.template.md" "$SESHAT_DIR/logbook.md"
  ok "$SESHAT_DIR/logbook.md aus Vorlage angelegt"
fi

CLAUDE_DIR="$HOME/.claude"
if [ -d "$CLAUDE_DIR" ]; then
  mkdir -p "$CLAUDE_DIR/agents"
  link "$REPO/claude/agents/thot.md" "$CLAUDE_DIR/agents/thot.md"
  link "$REPO/claude/agents/imhotep.md" "$CLAUDE_DIR/agents/imhotep.md"
  link "$REPO/claude/agents/horus.md" "$CLAUDE_DIR/agents/horus.md"
  link "$REPO/claude/agents/research.md" "$CLAUDE_DIR/agents/research.md"
  link "$REPO/claude/agents/seshat.md" "$CLAUDE_DIR/agents/seshat.md"

  CLAUDE_CMD_DIR="$CLAUDE_DIR/commands"
  mkdir -p "$CLAUDE_CMD_DIR"
  link "$REPO/claude/commands/start-work.md" "$CLAUDE_CMD_DIR/start-work.md"
  link "$REPO/claude/commands/review-plan.md" "$CLAUDE_CMD_DIR/review-plan.md"
  link "$REPO/claude/commands/start-learning.md" "$CLAUDE_CMD_DIR/start-learning.md"

  CLAUDE_SKILLS_DIR="$CLAUDE_DIR/skills"
  CAVEMAN_SRC="$HOME/.agents/skills/caveman"
  if [ -d "$CAVEMAN_SRC" ]; then
    mkdir -p "$CLAUDE_SKILLS_DIR"
    link "$CAVEMAN_SRC" "$CLAUDE_SKILLS_DIR/caveman"
  else
    skip "$CAVEMAN_SRC nicht gefunden; caveman muss manuell installiert werden"
  fi
else
  skip "$CLAUDE_DIR nicht gefunden; Claude Code übersprungen"
fi

cat <<'EOF'

Fertig.

WICHTIG: opencode neu starten. Die Konfiguration wird nur beim Start geladen.

Danach:
  Agent auf 'thot' wechseln und eine Aufgabe beschreiben
  /review-plan <slug>  lässt 'horus' den Plan vor der Umsetzung prüfen
  /start-work <slug>   führt den Plan mit 'imhotep' aus (nur nach APPROVED)
  /start-learning <slug>  führt den Plan mit 'seshat' aus, Lernaufgaben inklusive

Claude Code:
  claude/settings.example.json nach ~/.claude/settings.json kopieren
   context7 einmal registrieren:
     claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp --header "CONTEXT7_API_KEY: $CONTEXT7_API_KEY"
   Planung starten: claude --agent thot
   Review starten: claude --agent horus
   Umsetzung starten: claude --agent imhotep
   Umsetzung mit Lernaufgaben: claude --agent seshat
   /review-plan <slug>  lässt 'horus' den Plan vor der Umsetzung prüfen
   /start-work <slug>   führt den Plan mit 'imhotep' aus (nur nach APPROVED)
   /start-learning <slug>  führt den Plan mit 'seshat' aus, Lernaufgaben inklusive
   Claude Code neu starten, wenn ~/.claude/agents/ neu angelegt wurde
EOF
