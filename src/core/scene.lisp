(defpackage #:lab.scene
  (:use #:cl)
  (:export #:sprite #:make-sprite #:sprite-asset #:sprite-x #:sprite-y
           #:sprite-layer #:sprite-depth #:sprite-scale #:draw-order
           #:camera #:make-camera #:camera-x #:camera-y #:pan-camera
           #:screen-position))

(in-package #:lab.scene)

(defstruct sprite
  (asset "" :type string)
  (x 0 :type integer)
  (y 0 :type integer)
  (layer 0 :type integer)
  (depth 0 :type integer)
  (scale 1 :type (integer 1)))

(defun draw-order (sprites)
  "Return a new stable list, sorted by layer and foot position."
  (stable-sort (copy-list sprites)
               (lambda (a b)
                 (or (< (sprite-layer a) (sprite-layer b))
                     (and (= (sprite-layer a) (sprite-layer b))
                          (< (sprite-depth a) (sprite-depth b)))))))

(defstruct camera
  (x 0 :type integer)
  (y 0 :type integer))

(defun pan-camera (camera dx dy world-width world-height view-width view-height)
  "Clamp the camera's top-left corner to the available world bounds."
  (setf (camera-x camera)
        (min (max 0 (- world-width view-width))
             (max 0 (+ (camera-x camera) dx)))
        (camera-y camera)
        (min (max 0 (- world-height view-height))
             (max 0 (+ (camera-y camera) dy))))
  camera)

(defun screen-position (camera x y)
  (values (- x (camera-x camera)) (- y (camera-y camera))))
