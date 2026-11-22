(ql:quickload :cffi :silent t)
(pushnew #p"/opt/homebrew/lib/" cffi:*foreign-library-directories* :test #'equal)
;; Le serveur MCP n'écoute qu'en HTTP local : inutile de charger cl+ssl.
(pushnew :hunchentoot-no-ssl *features*)
(push (truename ".") asdf:*central-registry*)
;; game-kit : $GAME_KIT_DIR, sinon deux dossiers plus haut (examples/hello -> game-kit).
(push (uiop:ensure-directory-pathname
       (or (uiop:getenvp "GAME_KIT_DIR") (merge-pathnames "../../" (truename "."))))
      asdf:*central-registry*)
(ql:quickload :hello)
(hello:main)
(uiop:quit 0)
