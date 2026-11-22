(in-package #:game-kit/tests)

;;; Souris simulée. Seuls les chemins simulés sont testés : la souris réelle
;;; demande une fenêtre.

(def-suite input :description "Saisie simulée : souris.")
(in-suite input)

(defmacro with-clean-mouse (&body body)
  `(let ((game-kit::*simulated-mouse* nil)
         (game-kit::*simulated-mouse-anchor* nil)
         (game-kit::*simulated-buttons* (make-hash-table))
         (game-kit::*simulated-buttons-previous* (make-hash-table))
         (game-kit::*simulated-keys* (make-hash-table))
         (game-kit::*simulated-previous* (make-hash-table))
         (game-kit::*simulated-wheel* 0f0))
     ,@body))

(test simulated-position
  (with-clean-mouse
    (setf game-kit::*simulated-mouse* (cons 120 340))
    (is (= 120 (game-kit:mouse-x)))
    (is (= 340 (game-kit:mouse-y)))))

(test simulated-button-lifecycle
  "Un bouton tenu deux images : enfoncé à la première, tenu à la deuxième,
relâché à la troisième."
  (with-clean-mouse
    (setf (gethash :mouse-button-left game-kit::*simulated-buttons*) 2)
    (is (game-kit:mouse-button-pressed-p :mouse-button-left))
    (is (game-kit:mouse-button-down-p :mouse-button-left))
    (game-kit::advance-simulated-input)
    (is (game-kit:mouse-button-down-p :mouse-button-left))
    (is (gethash :mouse-button-left game-kit::*simulated-buttons-previous*))
    (game-kit::advance-simulated-input)
    (is (not (game-kit::simulated-button-down-p :mouse-button-left)))
    (is (game-kit:mouse-button-released-p :mouse-button-left))
    (game-kit::advance-simulated-input)
    (is (not (gethash :mouse-button-left game-kit::*simulated-buttons-previous*)))))

(test simulated-wheel-lasts-one-frame
  (with-clean-mouse
    (setf game-kit::*simulated-wheel* 2f0)
    (game-kit::advance-simulated-input)
    (is (= 0f0 game-kit::*simulated-wheel*))))

(test parse-button
  (is (eq :mouse-button-left (game-kit::parse-button "left")))
  (is (eq :mouse-button-right (game-kit::parse-button "RIGHT")))
  (signals error (game-kit::parse-button "fourth")))
