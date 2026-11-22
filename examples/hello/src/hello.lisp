(in-package #:hello)

;;; Exemple minimal : une scène qui fait rebondir un carré à pas fixe, compte les
;;; ticks sans allouer et réagit à Espace. À modifier pendant qu'il tourne :
;;; changer *SPEED* ou la couleur, puis game_reload.

(defparameter *speed* 240f0 "Vitesse du carré, en pixels par seconde.")
(defparameter *box-color* '(230 180 60 255))

(defclass bounce-scene (scene)
  ((clock :initform (make-fixed-clock :tick-rate 60) :reader scene-clock)
   (x :initform 100f0 :accessor box-x)
   (dx :initform 1f0 :accessor box-dx)
   (ticks :initform 0 :accessor scene-ticks)
   (tick-text :initform (make-text-buffer) :reader tick-text)))

(defmethod scene-update ((scene bounce-scene) dt)
  (when (key-pressed-p :key-space)
    (setf (box-dx scene) (- (box-dx scene))))
  (dotimes (i (clock-consume (scene-clock scene) dt))
    (incf (scene-ticks scene))
    (incf (box-x scene) (* (box-dx scene) *speed* (clock-tick-dt (scene-clock scene))))
    (cond ((< (box-x scene) 0) (setf (box-dx scene) 1f0))
          ((> (box-x scene) (- *window-width* 60)) (setf (box-dx scene) -1f0)))))

(defmethod scene-draw ((scene bounce-scene))
  (clear-background '(20 20 30))
  (draw-rectangle (round (box-x scene)) (floor *window-height* 2) 60 60 *box-color*)
  (draw-text "Ticks " 10 10 (text-size 30) :lightgray)
  (draw-text (write-integer-into (scene-ticks scene) (tick-text scene))
             (+ 10 (measure-text "Ticks " (text-size 30))) 10 (text-size 30) :white)
  (draw-text "Espace : demi-tour   ` : console" 10 (- *window-height* 40) (text-size 24) :gray))

(defmethod scene-snapshot ((scene bounce-scene))
  (ht "type" "bounce" "x" (round (box-x scene)) "ticks" (scene-ticks scene)))

(defvar *state* (make-game-state 'bounce-scene))

(defun main ()
  (run-game :title "hello" :system :hello :fullscreen nil))
