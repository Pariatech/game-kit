(in-package #:game-kit/tests)

(def-suite reload :description "Choix des fichiers recompilés par game_reload.")
(in-suite reload)

(defparameter *names* '("package" "mcp-server" "jobs" "input" "engine" "mcp-tools" "game"))
(defparameter *infrastructure* '("package" "mcp-server" "jobs" "mcp-tools"))

(defun plan (&rest changed)
  (multiple-value-list (game-kit::plan-reload *names* changed *infrastructure*)))

(test nothing-changed
  (is (equal '(() () ()) (plan))))

(test last-file
  (is (equal '(("game") () ()) (plan "game"))))

(test followers-recompiled-without-infrastructure
  (is (equal '(("engine" "game") ("mcp-tools") ()) (plan "engine")))
  (is (equal '(("input" "engine" "game") ("mcp-tools") ()) (plan "input"))))

(test order-follows-system-not-request
  (is (equal '(("input" "engine" "game") ("mcp-tools") ()) (plan "game" "input"))))

(test infrastructure-blocks-everything
  (is (equal '(() () ("mcp-tools")) (plan "mcp-tools")))
  (is (equal '(() () ("jobs" "mcp-tools")) (plan "game" "mcp-tools" "jobs"))))

(test normalize-file-name
  (is (string= "engine" (game-kit::normalize-file-name "engine" *names*)))
  (is (string= "engine" (game-kit::normalize-file-name "engine.lisp" *names*)))
  (is (string= "engine" (game-kit::normalize-file-name "src/engine.lisp" *names*)))
  (signals error (game-kit::normalize-file-name "nope" *names*)))

(test normalize-library-file-name
  "Les fichiers de game-kit se nomment game-kit/… ; leur nom de base suffit s'il
n'est pas ambigu."
  (let ((names '("game-kit/package" "game-kit/engine" "package" "battle")))
    (is (string= "game-kit/engine" (game-kit::normalize-file-name "game-kit/engine" names)))
    (is (string= "game-kit/engine" (game-kit::normalize-file-name "engine" names)))
    (is (string= "game-kit/engine" (game-kit::normalize-file-name "src/engine.lisp" names)))
    (is (string= "package" (game-kit::normalize-file-name "package" names)))
    (is (string= "battle" (game-kit::normalize-file-name "battle.lisp" names)))))

(test parse-file-list
  (is (equal '() (game-kit::parse-file-list nil)))
  (is (equal '("engine" "game") (game-kit::parse-file-list '("engine" "game"))))
  (is (equal '("src/engine.lisp") (game-kit::parse-file-list "[\"src/engine.lisp\"]")))
  (is (equal '("engine" "game") (game-kit::parse-file-list "engine, game")))
  (is (equal '("engine") (game-kit::parse-file-list "engine")))
  (signals error (game-kit::parse-file-list '(1 2))))
