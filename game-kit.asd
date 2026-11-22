(asdf:defsystem #:game-kit
  :description "Noyau d'un jeu raylib en Common Lisp modifiable à chaud par Claude
Code : serveur MCP local, outils game_*, console reliée à Claude, boucle, dessin
sans allocation, scènes, horloge à pas fixe, générateur à graine."
  :author "Gabriel Pariat"
  :license "MIT"
  :version "0.1.0"
  :depends-on (#:cl-raylib #:hunchentoot #:yason #:sb-concurrency #:sb-md5 #:sb-sprof)
  :serial t
  :pathname "src"
  :in-order-to ((asdf:test-op (asdf:test-op #:game-kit/tests)))
  :components ((:file "package")
               (:file "mcp-server")
               (:file "jobs")
               (:file "input")
               (:file "draw")
               (:file "engine")
               (:file "mcp-tools")
               (:file "console")
               (:file "rng")
               (:file "fixed-clock")
               (:file "scene")
               (:file "bench")))

(asdf:defsystem #:game-kit/tests
  :depends-on (#:game-kit #:fiveam)
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "jobs-tests")
               (:file "reload-tests")
               (:file "rng-tests")
               (:file "fixed-clock-tests")
               (:file "text-tests")
               (:file "input-tests"))
  :perform (asdf:test-op (o c)
             (when (member nil (mapcar (lambda (suite)
                                       (uiop:symbol-call :fiveam :run!
                                                         (uiop:find-symbol* suite :game-kit/tests)))
                                     '(:jobs :reload :rng :fixed-clock :text :input)))
               (error "Des tests ont échoué."))))
