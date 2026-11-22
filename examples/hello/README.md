# hello

Exemple minimal d'un jeu game-kit : un carré qui rebondit à pas fixe.

```sh
cd examples/hello
APP_ROOT=. ../../scripts/claude.sh     # jeu + Claude Code avec la console
APP_ROOT=. ../../scripts/dev.sh start   # le jeu seul, dans tmux
```

Pour un nouveau jeu, copier ce dossier à côté de game-kit, renommer `hello`, et dans `scripts/run.lisp` et `.mcp.json` remplacer le chemin de game-kit par `../game-kit`.
