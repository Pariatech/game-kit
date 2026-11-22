# game-kit

Noyau réutilisable d'un jeu Common Lisp (SBCL, raylib) modifiable à chaud par Claude Code. Le mode d'emploi, l'API et les règles sont dans `README.md` ; les mesures de rendu dans `docs/mesures.md`.

## Fichiers (`src/`, dans l'ordre de chargement)
- `package.lisp` : le package `game-kit` et tout ce qu'il exporte. Un symbole utilisé par un jeu doit y être.
- `mcp-server.lisp` : serveur MCP (Hunchentoot, JSON-RPC, 127.0.0.1, jeton Bearer, `Origin`/`Host` locaux), `define-mcp-tool`, `ht`, `to-json`, et `GET /console/outbox`.
- `jobs.lisp` : `call-in-main-thread`, `run-pending-jobs`, `*drawing-jobs*` (fin du dessin, pour les captures).
- `input.lisp` : clavier réel et simulé (`key-down-p`, `key-pressed-p`, `next-char`).
- `draw.lisp` : dessin et texte sans allocation, `text-size`.
- `engine.lisp` : `run-game`, `run-frame`, `update` et `draw` (génériques), `guarded`, mesure par section (`timed`), captures, plein écran.
- `mcp-tools.lisp` : outils `game_*`, rechargement (`*reload-systems*`, `*infrastructure-files*`, `record-loaded-digests`).
- `console.lisp` : console reliée à Claude.
- `rng.lisp`, `fixed-clock.lisp` : générateur PCG32, horloge à pas fixe.
- `scene.lisp` : scènes, `game-state`, `make-game-state`, `change-scene`.
- `bench.lisp` : `game_benchmark`, `game_profile`.

## Règles
- Rien de propre à un jeu ici : un réglage de jeu passe par un paramètre de `run-game` ou une variable spéciale exportée.
- Code chaud sans allocation (voir README) ; vérifier avec `game_profile` en mode `alloc`.
- Ne jamais affaiblir les contrôles de sécurité du serveur ; ne jamais versionner de jeton.
- Tests : `sbcl --non-interactive --load scripts/test.lisp` (sans fenêtre). Un jeu hôte (rogue-company) sert de test d'intégration : ses tests et `game_reload` doivent passer après un changement ici.
