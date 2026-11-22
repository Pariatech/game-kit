;;; Tests de game-kit : sbcl --non-interactive --load scripts/test.lisp
(ql:quickload :cffi :silent t)
;; Homebrew installe raylib ici ; ajouter d'autres dossiers au besoin.
(pushnew #p"/opt/homebrew/lib/" cffi:*foreign-library-directories* :test #'equal)
;; Le serveur MCP n'écoute qu'en HTTP local : inutile de charger cl+ssl.
(pushnew :hunchentoot-no-ssl *features*)
(push (truename ".") asdf:*central-registry*)
(ql:quickload '(:game-kit :fiveam) :silent t)
(uiop:quit (handler-case (progn (asdf:test-system :game-kit) 0)
             (error (e) (format t "~&~a~%" e) 1)))
