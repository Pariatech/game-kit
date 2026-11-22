(in-package #:game-kit)

;;; Le jeu lit le clavier par KEY-DOWN-P, qui combine le clavier réel et
;;; les touches simulées par l'outil game_input, sans focus de fenêtre.

(defvar *simulated-keys* (make-hash-table)
  "Touche raylib (mot-clé, par exemple :KEY-RIGHT) -> images restantes.")
(defvar *simulated-previous* (make-hash-table)
  "Touches simulées enfoncées à l'image précédente, pour KEY-PRESSED-P.")

(defun key-down-p (key)
  (or (plusp (gethash key *simulated-keys* 0))
      (raylib:is-key-down key)))

(defun mark-simulated-keys-seen ()
  "Les touches et boutons simulés tenus ne comptent plus comme tout juste enfoncés."
  (maphash (lambda (key frames)
             (declare (ignore frames))
             (setf (gethash key *simulated-previous*) t))
           *simulated-keys*)
  (maphash (lambda (button frames)
             (declare (ignore frames))
             (setf (gethash button *simulated-buttons-previous*) t))
           *simulated-buttons*))

(defun count-down (table)
  "Retire une image à chaque entrée de TABLE, et les entrées arrivées à zéro."
  (loop for key in (loop for k being the hash-keys of table collect k)
        do (when (<= (decf (gethash key table)) 0)
             (remhash key table))))

(defun advance-simulated-input ()
  "Consomme une image de chaque touche et bouton simulés, et la molette simulée."
  (clrhash *simulated-previous*)
  (clrhash *simulated-buttons-previous*)
  (mark-simulated-keys-seen)
  (count-down *simulated-keys*)
  (count-down *simulated-buttons*)
  (setf *simulated-wheel* 0f0))

(defun advance-input ()
  "Fin d'une image de saisie. Appelé après chaque update."
  (advance-simulated-input)
  (release-simulated-mouse-if-moved))

;;; Souris : le jeu la lit par MOUSE-X, MOUSE-Y, MOUSE-BUTTON-DOWN-P,
;;; MOUSE-BUTTON-PRESSED-P, MOUSE-BUTTON-RELEASED-P et MOUSE-WHEEL-MOVE, qui
;;; combinent la souris réelle et celle simulée par game_input. La position
;;; simulée tient jusqu'à ce que la souris réelle bouge ; un bouton simulé est
;;; tenu un nombre d'images, comme une touche ; la molette simulée vaut pour une
;;; image.

(defvar *simulated-mouse* nil
  "Position simulée (x . y) en pixels de la fenêtre, ou NIL : la souris réelle.")
(defvar *simulated-mouse-anchor* nil
  "Position réelle (x . y) au moment de la simulation : la quitter rend la main.")
(defvar *simulated-buttons* (make-hash-table)
  "Bouton raylib (:MOUSE-BUTTON-LEFT…) -> images restantes.")
(defvar *simulated-buttons-previous* (make-hash-table)
  "Boutons simulés enfoncés à l'image précédente.")
(defvar *simulated-wheel* 0f0 "Molette simulée de l'image en cours.")

(defun simulate-mouse-position (x y)
  "Place la souris simulée en (X, Y). Thread principal."
  (setf *simulated-mouse* (cons x y)
        *simulated-mouse-anchor* (cons (raylib:get-mouse-x) (raylib:get-mouse-y))))

(defun release-simulated-mouse-if-moved ()
  (let ((anchor *simulated-mouse-anchor*))
    (when (and anchor
               (or (/= (car anchor) (raylib:get-mouse-x))
                   (/= (cdr anchor) (raylib:get-mouse-y))))
      (setf *simulated-mouse* nil
            *simulated-mouse-anchor* nil))))

(defun mouse-x ()
  (if *simulated-mouse* (car *simulated-mouse*) (raylib:get-mouse-x)))

(defun mouse-y ()
  (if *simulated-mouse* (cdr *simulated-mouse*) (raylib:get-mouse-y)))

(defun simulated-button-down-p (button)
  (plusp (gethash button *simulated-buttons* 0)))

(defun mouse-button-down-p (button)
  "BUTTON : :MOUSE-BUTTON-LEFT, :MOUSE-BUTTON-RIGHT ou :MOUSE-BUTTON-MIDDLE."
  (or (simulated-button-down-p button)
      (raylib:is-mouse-button-down button)))

(defun mouse-button-pressed-p (button)
  "Vrai à la première image où BUTTON est enfoncé."
  (or (and (simulated-button-down-p button)
           (not (gethash button *simulated-buttons-previous*)))
      (raylib:is-mouse-button-pressed button)))

(defun mouse-button-released-p (button)
  "Vrai à la première image où BUTTON n'est plus enfoncé."
  (or (and (gethash button *simulated-buttons-previous*)
           (not (simulated-button-down-p button)))
      (raylib:is-mouse-button-released button)))

(defun mouse-wheel-move ()
  "Mouvement de la molette pendant l'image, réelle et simulée."
  (+ *simulated-wheel* (raylib:get-mouse-wheel-move)))

;;; Saisie de texte : la console lit les caractères par NEXT-CHAR, qui donne
;;; d'abord les caractères simulés par game_input (paramètre text), puis ceux
;;; du clavier réel. Un saut de ligne simulé vaut la touche Entrée.

(defvar *simulated-chars* (sb-concurrency:make-queue :name "simulated-chars")
  "Caractères en attente, déposés par game_input.")

(defun simulate-text (text)
  "Ajoute TEXT à la saisie simulée. Peut être appelé depuis n'importe quel thread."
  (loop for char across text
        do (sb-concurrency:enqueue char *simulated-chars*)))

(defun next-char ()
  "Renvoie le prochain caractère saisi, ou NIL. À appeler une fois par
caractère, jusqu'à NIL, à chaque image."
  (or (sb-concurrency:dequeue *simulated-chars*)
      (let ((code (raylib:get-char-pressed)))
        (when (plusp code) (code-char code)))))

(defun key-pressed-p (key &key repeat)
  "Vrai si KEY vient d'être enfoncée, ou répétée si REPEAT. Une touche simulée
par game_input compte comme enfoncée à la première image où elle est tenue."
  (or (and (plusp (gethash key *simulated-keys* 0))
           (not (gethash key *simulated-previous*)))
      (raylib:is-key-pressed key)
      (and repeat (raylib:is-key-pressed-repeat key))))
