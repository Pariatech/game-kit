#!/bin/sh
# Démarre, arrête et affiche un jeu game-kit dans une session tmux.
# Usage : dev.sh start|stop|restart|logs [lignes]
#
# Variables :
#   APP_ROOT          dossier du jeu (par défaut : le dossier courant)
#   GAME_KIT_SESSION  nom de la session tmux (par défaut : nom du dossier du jeu)
#   GAME_KIT_RUN      script Lisp de lancement, relatif à APP_ROOT (scripts/run.lisp)
#   GAME_KIT_HEAP     taille du tas de SBCL (4GB)
#   GAME_KIT_PORT     port du serveur MCP (7777)
set -eu

KIT=$(cd "$(dirname "$0")/.." && pwd)
APP_ROOT=$(cd "${APP_ROOT:-.}" && pwd)
SESSION=${GAME_KIT_SESSION:-$(basename "$APP_ROOT")}
RUN=${GAME_KIT_RUN:-scripts/run.lisp}
HEAP=${GAME_KIT_HEAP:-4GB}
PORT=${GAME_KIT_PORT:-7777}

running() { tmux has-session -t "$SESSION" 2>/dev/null; }

start() {
  if running; then
    echo "Déjà lancé (session tmux $SESSION)."
    return
  fi
  . "$KIT/scripts/token.sh"
  tmux new-session -d -s "$SESSION" -c "$APP_ROOT" -x 200 -y 50 \
    -e "LISP_GAME_MCP_TOKEN=$LISP_GAME_MCP_TOKEN" \
    -e "GAME_KIT_DIR=$KIT" \
    -e "GAME_KIT_PORT=$PORT" \
    "sbcl --dynamic-space-size $HEAP --load $RUN"
  # Garde la console lisible si SBCL s'arrête sur une erreur.
  tmux set-option -t "$SESSION" remain-on-exit on >/dev/null
  echo "Lancé dans la session tmux $SESSION. Console : dev.sh logs"
}

stop() {
  if running; then
    tmux kill-session -t "$SESSION"
    echo "Arrêté."
  else
    echo "Pas lancé."
  fi
}

logs() {
  if running; then
    tmux capture-pane -p -t "$SESSION" -S "-${1:-100}"
  else
    echo "Pas lancé."
  fi
}

case "${1:-}" in
  start) start ;;
  stop) stop ;;
  restart) stop; start ;;
  logs) logs "${2:-100}" ;;
  *) echo "Usage : $0 start|stop|restart|logs [lignes]" >&2; exit 2 ;;
esac
