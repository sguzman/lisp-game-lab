(in-package #:lab.playground)

(defun update-world (world)
  (lab.core:move-world world
                       (* 4 (lab.raylib:input-x))
                       (* 4 (lab.raylib:input-y))))

(defun render-world (world)
  (lab.raylib:begin-frame)
  (unwind-protect
       (progn
         (lab.raylib:draw-item (lab.core:world-x world)
                              (lab.core:world-y world)
                              lab.core:+item-size+)
         (lab.raylib:draw-label "Lisp Game Lab | Arrow keys to move"))
    (lab.raylib:end-frame)))

(defun run (bridge &key frame-limit)
  (let ((world (lab.core:make-world)))
    (lab.raylib:load-bridge bridge)
    (lab.raylib:open-window lab.core:+width+ lab.core:+height+
                            "Lisp Game Lab")
    (unwind-protect
         (loop for frame from 0
               until (or (and frame-limit (>= frame frame-limit))
                         (lab.raylib:should-close-p))
               do (update-world world)
                  (render-world world))
      (lab.raylib:close-window))))
