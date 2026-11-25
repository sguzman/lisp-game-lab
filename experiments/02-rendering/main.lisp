(in-package #:lab.rendering)

(defconstant +world-width+ 1280)
(defconstant +world-height+ 896)

(defun make-room ()
  (let ((sprites
          (loop for y from 0 below +world-height+ by 128
                append (loop for x from 0 below +world-width+ by 128
                             collect (lab.scene:make-sprite
                                      :asset "floor.png" :x x :y y
                                      :scale 4 :layer 0)))))
    (lab.scene:draw-order
     (append sprites
             (list (lab.scene:make-sprite :asset "rug.png" :x 352 :y 208
                                          :scale 8 :layer 1)
                   (lab.scene:make-sprite :asset "crate.png" :x 520 :y 280
                                          :scale 4 :layer 2 :depth 408)
                   (lab.scene:make-sprite :asset "plant.png" :x 572 :y 230
                                          :scale 4 :layer 2 :depth 358)
                   (lab.scene:make-sprite :asset "plant.png" :x 850 :y 480
                                          :scale 4 :layer 2 :depth 608)
                   (lab.scene:make-sprite :asset "crate.png" :x 1080 :y 730
                                          :scale 4 :layer 2 :depth 858))))))

(defun acquire-textures (sprites root cache)
  "Populate CACHE incrementally so partial acquisition can be unwound."
  (dolist (sprite sprites)
    (let ((asset (lab.scene:sprite-asset sprite)))
      (unless (gethash asset cache)
        (setf (gethash asset cache)
              (lab.raylib:load-texture (merge-pathnames asset root)))))))

(defun release-textures (cache)
  (maphash (lambda (key handle)
             (declare (ignore key))
             (lab.raylib:unload-texture handle))
           cache)
  (clrhash cache))

(defun render-room (sprites camera cache)
  (lab.raylib:begin-frame)
  (unwind-protect
       (progn
         (dolist (sprite sprites)
           (multiple-value-bind (x y)
               (lab.scene:screen-position camera
                                          (lab.scene:sprite-x sprite)
                                          (lab.scene:sprite-y sprite))
             (lab.raylib:draw-texture (gethash (lab.scene:sprite-asset sprite) cache)
                                      x y (lab.scene:sprite-scale sprite))))
         (lab.raylib:draw-label "02 | Arrow keys pan the camera | Esc exits"))
    (lab.raylib:end-frame)))

(defun run (bridge &key frame-limit)
  (let ((sprites (make-room))
        (camera (lab.scene:make-camera))
        (cache (make-hash-table :test #'equal))
        (root (asdf:system-relative-pathname
               "lisp-game-lab" "assets/02-rendering/")))
    (lab.raylib:load-bridge bridge)
    (lab.raylib:open-window lab.core:+width+ lab.core:+height+
                            "Lisp Game Lab | Rendering")
    (unwind-protect
         (progn
           (acquire-textures sprites root cache)
           (assert (= 4 (hash-table-count cache)))
           (let ((frames 0))
             (loop until (or (and frame-limit (>= frames frame-limit))
                             (lab.raylib:should-close-p))
                   do (lab.scene:pan-camera
                       camera (* 6 (lab.raylib:input-x))
                       (* 6 (lab.raylib:input-y))
                       +world-width+ +world-height+
                       lab.core:+width+ lab.core:+height+)
                      (render-room sprites camera cache)
                      (incf frames))
             (when frame-limit
               (assert (= frames frame-limit))
               (format t "~&Rendering smoke: ~D frames, ~D unique textures.~%"
                       frames (hash-table-count cache)))))
      (unwind-protect
           (release-textures cache)
        (lab.raylib:close-window)))))
