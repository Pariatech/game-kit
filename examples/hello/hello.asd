(asdf:defsystem #:hello
  :description "Exemple minimal d'un jeu game-kit."
  :depends-on (#:game-kit)
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "hello")))
