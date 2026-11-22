# game-kit

Noyau d'un jeu en Common Lisp (SBCL, raylib) que Claude Code modifie **à chaud**, pendant qu'il tourne, par MCP. Tiré de [rogue-company](https://github.com/Pariatech/rogue-company), pour être réutilisé dans d'autres jeux.

## Contenu

- **Boucle de jeu** (`engine.lisp`) :
  - une image par passage : tâches en attente, console, `update`, `draw`, captures ;
  - erreurs gardées : une erreur met le jeu en pause et s'affiche, sans tuer le processus ;
  - pas à pas, plein écran (natif sous macOS) ;
  - temps et octets alloués mesurés par section.
- **Serveur MCP local** (`mcp-server.lisp`) :
  - JSON-RPC sur HTTP (Hunchentoot), sur `127.0.0.1` seulement ;
  - jeton Bearer obligatoire, en-têtes `Origin` et `Host` non locaux refusés.
- **Outils `game_*`** (`mcp-tools.lisp`) :
  - `game_eval` : évaluer du Lisp dans le jeu ;
  - `game_reload` : recompiler et recharger les fichiers modifiés, en gardant l'état ;
  - `game_state` : état du jeu en JSON ;
  - `game_screenshot` : capture d'écran ;
  - `game_input` : touches, texte et souris (position, boutons, molette) simulés ;
  - `game_control` : pause, reprise, pas à pas ;
  - `game_console_reply` : réponse dans la console du jeu ;
  - `game_benchmark` et `game_profile` : mesures de rendu et profilage ;
  - `game_ping`.
- **File de tâches** (`jobs.lisp`) : les outils tournent sur les threads du serveur. Tout ce qui touche raylib ou l'état passe sur le thread principal par `call-in-main-thread`.
- **Console** (`console.lisp`) :
  - la touche `` ` `` l'ouvre et met le jeu en pause ;
  - le joueur écrit à la session Claude Code, qui répond dans la console (`game_console_reply`) ;
  - le pont `bridge/server.ts` (Bun) transmet les messages en notifications `claude/channel`.
- **Saisie** (`input.lisp`) : `key-down-p`, `key-pressed-p` et `next-char` combinent le clavier réel et la saisie simulée par `game_input`. De même pour la souris : `mouse-x`, `mouse-y`, `mouse-button-down-p`, `mouse-button-pressed-p`, `mouse-button-released-p`, `mouse-wheel-move`. La position simulée tient jusqu'à ce que la souris réelle bouge.
- **Dessin et texte sans allocation** (`draw.lisp`) :
  - `clear-background`, `draw-rectangle`, `draw-line`, `draw-text`, `measure-text` ;
  - couleurs passées en `uint32`, texte encodé en UTF-8 dans un tampon C ;
  - nombres affichés avec `write-integer-into` ;
  - tailles de texte proportionnelles à la fenêtre (`text-size`).
- **Scènes** (`scene.lisp`) : protocole `scene-update`, `scene-draw`, `scene-enter`, `scene-exit` et `scene-snapshot`, avec `game-state` et `change-scene`.
- **Horloge à pas fixe** (`fixed-clock.lisp`) : simulation déterministe à N ticks par seconde, vitesse réglable, interpolation du dessin.
- **Générateur à graine** (`rng.lisp`) : PCG32 sans allocation. Même suite d'une version de SBCL à l'autre.
- **Banc d'essai de rendu** (`bench.lisp`) : 10 000 sprites par `DrawTexturePro` ou par `rlgl`. Voir [docs/mesures.md](docs/mesures.md).

## Prérequis

- SBCL (testé avec la 2.6.10), Quicklisp ;
- raylib installé (Homebrew : `/opt/homebrew/lib`), [cl-raylib](https://github.com/longlene/cl-raylib) ;
- Bun, pour le pont de la console ;
- tmux, pour `scripts/dev.sh`.

`cl-raylib` vise raylib 5.0. Avant d'utiliser une nouvelle fonction raylib, comparer sa signature avec `raylib.h`.

## Démarrer un jeu

Le plus court chemin est de copier [`examples/hello`](examples/hello) à côté de `game-kit` et de le renommer.

**1. Le système ASDF du jeu dépend de `game-kit` :**

```lisp
(asdf:defsystem #:hello
  :depends-on (#:game-kit)
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "hello")))
```

**2. Le package utilise `game-kit` :**

```lisp
(defpackage #:hello
  (:use #:cl #:game-kit)
  (:export #:main))
```

**3. Une scène, l'état, le lancement :**

```lisp
(in-package #:hello)

(defclass title-scene (scene) ())

(defmethod scene-draw ((scene title-scene))
  (clear-background :black)
  (draw-text-centered "Bonjour" (floor *window-width* 2) 100 (text-size 60) :white))

(defvar *state* (make-game-state 'title-scene))

(defun main ()
  (run-game :title "hello" :system :hello))
```

`run-game` doit tourner sur le thread principal. Ses options :

- `:width` et `:height` : taille de la fenêtre ;
- `:port` : port du serveur MCP (7777 par défaut) ;
- `:package` : package de `game_eval` (par défaut celui du système) ;
- `:fullscreen` : ouvrir en plein écran ;
- `:target-fps` : images par seconde visées ;
- `:escape-closes` : par défaut, Échap reste au jeu au lieu de fermer la fenêtre.

**4. `scripts/run.lisp` dans le jeu.** Il trouve `game-kit` par `$GAME_KIT_DIR`, sinon dans `../game-kit` :

```lisp
(ql:quickload :cffi :silent t)
(pushnew #p"/opt/homebrew/lib/" cffi:*foreign-library-directories* :test #'equal)
(pushnew :hunchentoot-no-ssl *features*)
(push (truename ".") asdf:*central-registry*)
(push (uiop:ensure-directory-pathname
       (or (uiop:getenvp "GAME_KIT_DIR") (merge-pathnames "../game-kit/" (truename "."))))
      asdf:*central-registry*)
(ql:quickload :hello)
(hello:main)
(uiop:quit 0)
```

**5. `.mcp.json` à la racine du jeu.** Le nom du serveur, ici `hello`, est celui que le pont annonce à Claude :

```json
{
  "mcpServers": {
    "hello": {
      "type": "http",
      "url": "http://127.0.0.1:7777/mcp",
      "headers": { "Authorization": "Bearer ${LISP_GAME_MCP_TOKEN}" }
    },
    "game-console": {
      "type": "stdio",
      "command": "bun",
      "args": ["run", "${GAME_KIT_DIR:-../game-kit}/bridge/server.ts"],
      "env": {
        "LISP_GAME_MCP_TOKEN": "${LISP_GAME_MCP_TOKEN}",
        "GAME_NAME": "hello",
        "GAME_MCP_SERVER": "hello"
      }
    }
  }
}
```

**6. Ajouter `.mcp-token` et `captures/` au `.gitignore` du jeu, puis lancer :**

```sh
APP_ROOT=. ../game-kit/scripts/claude.sh   # lance le jeu, attend le serveur, ouvre Claude Code avec la console
APP_ROOT=. ../game-kit/scripts/dev.sh logs  # start | stop | restart | logs
```

rogue-company garde deux petits scripts, `scripts/dev.sh` et `scripts/claude.sh`, qui fixent ces variables et appellent ceux de `game-kit`.

## Les scripts

| Script | Rôle |
| --- | --- |
| `scripts/token.sh` | À sourcer avec `APP_ROOT`. Exporte `LISP_GAME_MCP_TOKEN` : celui de l'environnement, sinon `$APP_ROOT/.mcp-token`, créé au premier usage en mode 600. |
| `scripts/dev.sh` | `start`, `stop`, `restart`, `logs` : le jeu dans une session tmux. |
| `scripts/claude.sh` | Lance le jeu s'il ne tourne pas, attend le serveur MCP, vérifie le jeton, puis lance `claude --dangerously-load-development-channels server:game-console`. |
| `scripts/test.lisp` | Les tests de `game-kit`. |

Variables communes :

- `APP_ROOT` : dossier du jeu, le dossier courant par défaut ;
- `GAME_KIT_SESSION` : session tmux, le nom du dossier par défaut ;
- `GAME_KIT_RUN` : script de lancement, `scripts/run.lisp` par défaut ;
- `GAME_KIT_HEAP` : taille du tas de SBCL, `4GB` par défaut ;
- `GAME_KIT_PORT` : port du serveur MCP, 7777 par défaut. Le serveur Lisp et le pont le lisent aussi ; l'URL de `.mcp.json` doit suivre.

## Rechargement à chaud

`game_reload` recompile les fichiers modifiés depuis leur dernier chargement, plus tous ceux qui les suivent dans l'ordre de chargement. L'ordre est celui de `game-kit`, puis celui du jeu.

- **Tout ou rien :** tout est compilé avant que rien ne soit chargé. Un avertissement (pas un style-warning) bloque tout le chargement.
- **Noms des fichiers :** ceux du jeu par leur nom (`battle`), ceux de `game-kit` sous la forme `game-kit/engine`. Le nom de base suffit s'il n'est pas ambigu.
- **Fichiers jamais rechargés à chaud** (`*infrastructure-files*`) :
  - les deux `package.lisp` ;
  - `game-kit/mcp-server`, `game-kit/jobs` et `game-kit/mcp-tools`, qui portent l'outil en cours d'exécution.

  Les modifier, ou modifier une macro qu'ils utilisent, demande `dev.sh restart`.

Règles pour que le rechargement garde l'état :

- `defvar` pour tout état qui doit survivre, `defparameter` pour un réglage qui reprend la valeur du fichier ;
- `defclass` pour l'état qui évolue, jamais `defstruct` : une instance existante suit le changement de sa classe ;
- un nouveau fichier s'ajoute dans le `.asd` du jeu, puis `dev.sh restart`.

## Ajouter un outil MCP

```lisp
(define-mcp-tool "game_spawn"
    ((kind "kind" "string" "Type d'unité." :required t :enum ("pikes" "shot"))
     (count "count" "integer" "Nombre (1 par défaut)."))
    "Ajoute des unités sous la souris."
  (call-in-main-thread (lambda () (spawn kind (or count 1))))
  "Fait.")
```

Les paramètres sont des listes de cette forme : `(variable "nom-json" type description &key required enum)`. Le corps tourne sur un thread du serveur et renvoie une chaîne. Tout accès à raylib ou à `*state*` passe par `call-in-main-thread`, qui interrompt une tâche au bout de 2 s.

L'état décrit par `game_state` vient de `game-snapshot`. Avec `game-state`, c'est le `scene-snapshot` de la scène courante. Il se spécialise avec `ht` (table JSON) et `json-value`.

## Dessin sans allocation : les règles

Mesures et explications dans [docs/mesures.md](docs/mesures.md).

- **Pas de fonction raylib qui prend ou renvoie une structure par valeur dans le code chaud** (`DrawTexturePro`, `Rectangle`, `Vector2`, `Color`…). Pour ces fonctions, CFFI passe par libffi et cherche le symbole C à chaque appel : 82 ms pour 10 000 sprites.
- **Passer par `rlgl` et ses arguments scalaires** :
  - un lot de quads (`rlgl:begin 7`, `rlgl::texcoord-2f`, `rlgl:vertex-2f`), voir `draw-bench-rlgl` dans `bench.lisp` : 0,76 ms pour 10 000 sprites ;
  - ou les fonctions de `draw.lisp`, qui passent la couleur en `uint32`.
  - `cl-rlgl` exporte par erreur `textcoord-2f` : la fonction s'appelle `rlgl::texcoord-2f`.
- **Pas de `format` pour un nombre qui change à chaque image** : utiliser `write-integer-into` dans un tampon de `make-text-buffer`.
- **Vérifier** avec `game_profile` en mode `alloc`.

## Règles du jeu hôte

- **raylib :** ne jamais l'appeler hors du thread principal ; passer par `call-in-main-thread`.
- **Clavier et souris :** les lire avec `key-down-p` et `key-pressed-p` (et `next-char`), `mouse-x`, `mouse-y`, `mouse-button-*-p` et `mouse-wheel-move`, jamais `raylib:is-key-down` ou `raylib:get-mouse-x`, sinon `game_input` est sans effet.
- **Simulation :** tout tirage aléatoire passe par `make-rng` et `rng-*`, jamais par `random`, pour qu'elle se rejoue à l'identique.
- **Float traps :** masqués seulement autour de la boucle principale (`run-game` s'en charge).
- **Noms :** ne pas nommer une fonction d'après un symbole de `CL` (`speed`, `step`…) : verrou de package de SBCL.
- **Fenêtre cachée :** macOS la ralentit (environ 9 images/s). Pour tester la logique, préférer `game_control` `step`.

## Sécurité

- Le serveur n'écoute que sur `127.0.0.1` et exige le jeton `LISP_GAME_MCP_TOKEN` (32 caractères minimum). Il refuse les en-têtes `Origin` et `Host` non locaux. **Ne jamais affaiblir ces contrôles :** `game_eval` évalue du Lisp arbitraire.
- Ne jamais versionner le jeton (`.mcp-token`).
- Le pont n'ouvre aucun port. Il relève `GET /console/outbox` avec le jeton et refuse une URL qui n'est pas locale.

## Tests

```sh
sbcl --non-interactive --load scripts/test.lisp
```

Les suites couvrent :

- la file de tâches ;
- le choix des fichiers rechargés ;
- le générateur ;
- l'horloge ;
- le texte sans allocation ;
- la souris simulée.

Tout tourne sans fenêtre.

## Licence

MIT.
