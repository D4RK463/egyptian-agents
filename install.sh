#!/usr/bin/env bash
# Symlinkt thot + imhotep und den /start-work Command in die globale
# opencode-Konfiguration. Idempotent. Fasst nichts an, was kein Symlink ist.
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

cat <<'EOF'

Fertig.

WICHTIG: opencode neu starten. Die Konfiguration wird nur beim Start geladen.

Danach:
  Agent auf 'thot' wechseln und eine Aufgabe beschreiben
  /start-work <slug>   führt den Plan mit 'imhotep' aus
EOF
