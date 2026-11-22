#!/bin/sh
# Lance le jeu s'il ne tourne pas, puis Claude Code avec le channel de la
# console du jeu. Les arguments sont passés à claude (ex. --continue).
# Usage : claude.sh [arguments de claude]
#
# Variables : celles de dev.sh, plus GAME_KIT_PORT (7777), le port du serveur MCP.
set -eu

KIT=$(cd "$(dirname "$0")/.." && pwd)
APP_ROOT=$(cd "${APP_ROOT:-.}" && pwd)
PORT=${GAME_KIT_PORT:-7777}
export APP_ROOT GAME_KIT_DIR="$KIT"
cd "$APP_ROOT"

if [ ! -d "$KIT/bridge/node_modules" ]; then
  echo "Installation des dépendances du pont (bun install)..."
  (cd "$KIT/bridge" && bun install)
fi

# Jeton partagé par le jeu et Claude Code (voir token.sh).
. "$KIT/scripts/token.sh"

# Ne fait rien si le jeu tourne déjà.
"$KIT/scripts/dev.sh" start

# Le serveur MCP démarre avec le jeu : l'attendre pour que Claude Code s'y
# connecte du premier coup.
tries=0
until curl -s -o /dev/null --max-time 1 "http://127.0.0.1:$PORT/mcp"; do
  tries=$((tries + 1))
  if [ "$tries" -ge 60 ]; then
    echo "Le serveur MCP ne répond pas après 60 s. Voir : dev.sh logs" >&2
    exit 1
  fi
  sleep 1
done

# Un jeu lancé avec un autre jeton refuserait Claude Code (401).
status=$(curl -s -o /dev/null -w '%{http_code}' --max-time 1 \
  -H "Authorization: Bearer $LISP_GAME_MCP_TOKEN" "http://127.0.0.1:$PORT/mcp")
if [ "$status" = 401 ]; then
  echo "Le jeu tourne avec un autre jeton. Relance-le : dev.sh restart" >&2
  exit 1
fi

exec claude --dangerously-load-development-channels server:game-console "$@"
