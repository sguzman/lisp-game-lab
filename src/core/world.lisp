(in-package #:lab.core)

(defconstant +width+ 800)
(defconstant +height+ 480)
(defconstant +item-size+ 64)

(defclass world ()
  ((x :initarg :x :initform 368 :accessor world-x)
   (y :initarg :y :initform 208 :accessor world-y))
  (:documentation "Mutable domain state; no window or GPU resources."))

(defun make-world (&key (x 368) (y 208))
  (let ((world (make-instance 'world)))
    (move-world world (- x (world-x world)) (- y (world-y world)))
    world))

(defun move-world (world dx dy)
  "Move WORLD by integer deltas, constrained to the logical viewport."
  (check-type dx integer)
  (check-type dy integer)
  (setf (world-x world)
        (min (- +width+ +item-size+) (max 0 (+ (world-x world) dx)))
        (world-y world)
        (min (- +height+ +item-size+) (max 0 (+ (world-y world) dy))))
  world)
