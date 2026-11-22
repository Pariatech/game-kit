(defpackage #:game-kit
  (:use #:cl)
  (:documentation "Noyau d'un jeu raylib en Common Lisp (SBCL) modifiable à chaud
par Claude Code : boucle, serveur MCP local, outils game_*, file de tâches vers
le thread principal, console reliée à Claude, dessin et texte sans allocation,
scènes, horloge à pas fixe, générateur à graine. Voir README.md.")
  (:export
   ;; Lancement (engine.lisp)
   #:run-game #:*state* #:update #:draw #:game-snapshot
   #:*window-width* #:*window-height* #:*window-title* #:*start-fullscreen*
   #:*frame* #:*paused* #:*last-error* #:*fixed-dt* #:*captures-directory*
   #:*draw-override* #:guarded #:clear-error #:capture-screen
   #:toggle-fullscreen-window
   ;; Scènes (scene.lisp)
   #:scene #:scene-update #:scene-draw #:scene-enter #:scene-exit #:scene-snapshot
   #:game-state #:make-game-state #:current-scene #:change-scene
   ;; Serveur et outils MCP (mcp-server.lisp, mcp-tools.lisp)
   #:*mcp-port* #:*mcp-address* #:*mcp-server-name* #:*mcp-token-variable*
   #:define-mcp-tool #:ht #:to-json #:json-value
   #:*eval-package* #:*reload-systems* #:*infrastructure-files*
   ;; File de tâches (jobs.lisp)
   #:call-in-main-thread #:run-pending-jobs #:*jobs* #:*drawing-jobs*
   #:job-error #:job-error-message #:job-error-backtrace
   ;; Saisie (input.lisp)
   #:key-down-p #:key-pressed-p #:next-char #:simulate-text #:*simulated-keys*
   ;; Dessin sans allocation (draw.lisp)
   #:color-value #:clear-background #:draw-rectangle #:draw-line
   #:draw-text #:draw-text-centered #:measure-text #:text-size
   #:*text-reference-height* #:*min-text-size*
   #:make-text-buffer #:write-integer-into #:encode-utf8-into #:with-c-text
   ;; Console (console.lisp)
   #:*console* #:*console-toggle-char* #:console-open-p
   #:console-add-reply #:console-take-outbox
   ;; Horloge à pas fixe (fixed-clock.lisp)
   #:fixed-clock #:make-fixed-clock #:*default-tick-rate* #:clock-consume
   #:clock-alpha #:clock-reset #:clock-time-scale #:clock-paused-p
   #:clock-tick-dt #:clock-dropped #:*max-time-scale*
   ;; Générateur à graine (rng.lisp)
   #:rng #:make-rng #:copy-rng #:rng-next #:rng-below #:rng-float #:rng-range
   ;; Banc d'essai de rendu (bench.lisp)
   #:run-benchmark #:run-profile))
