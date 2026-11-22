(in-package #:game-kit)

;;; Protocole des scènes et changement de scène.
;;;
;;; Une scène est une instance d'une sous-classe de SCENE qui spécialise
;;; SCENE-UPDATE et SCENE-DRAW, et au besoin SCENE-ENTER, SCENE-EXIT et
;;; SCENE-SNAPSHOT. GAME-STATE tient la scène courante et délègue UPDATE, DRAW et
;;; GAME-SNAPSHOT (engine.lisp) ; on en change avec CHANGE-SCENE. Le jeu crée son
;;; état avec (defvar *state* (make-game-state 'menu)).

(defclass scene () ())

(defgeneric scene-update (scene dt)
  (:documentation "Avance la scène de DT secondes. Pas appelé en pause.")
  (:method ((scene scene) dt) (declare (ignore dt))))

(defgeneric scene-draw (scene)
  (:documentation "Dessine la scène. Appelé à chaque image, même en pause.")
  (:method ((scene scene)) (clear-background :black)))

(defgeneric scene-enter (scene)
  (:documentation "Appelé quand la scène devient la scène courante.")
  (:method ((scene scene))))

(defgeneric scene-exit (scene)
  (:documentation "Appelé quand la scène cesse d'être la scène courante.")
  (:method ((scene scene))))

(defgeneric scene-snapshot (scene)
  (:documentation "Résumé de la scène pour game_state : table de hachage JSON.")
  (:method ((scene scene))
    (ht "type" (string-downcase (class-name (class-of scene))))))

(defclass game-state ()
  ((scene :initarg :scene :accessor current-scene))
  (:documentation "État d'un jeu fait de scènes : la scène courante."))

(defun make-game-state (scene)
  "État dont la scène courante est SCENE (une instance, ou le nom de sa classe),
déjà entrée (SCENE-ENTER)."
  (let ((state (make-instance 'game-state
                              :scene (if (symbolp scene) (make-instance scene) scene))))
    (scene-enter (current-scene state))
    state))

(defmethod update ((state game-state) dt)
  (scene-update (current-scene state) dt))

(defmethod draw ((state game-state))
  (scene-draw (current-scene state)))

(defmethod game-snapshot ((state game-state))
  (ht "scene" (scene-snapshot (current-scene state))))

;;; Changement de scène

(defun change-scene (state scene)
  "Remplace la scène courante de STATE par SCENE (une instance, ou le nom de sa
classe, créée après la sortie de l'ancienne)."
  ;; L'ancienne scène sort d'abord : ce qu'elle écrit en sortant (une
  ;; sauvegarde, un replay) est prêt quand la nouvelle se crée.
  (scene-exit (current-scene state))
  (let ((scene (if (symbolp scene) (make-instance scene) scene)))
    (setf (current-scene state) scene)
    (scene-enter scene)
    scene))
