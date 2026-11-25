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
         (let ((frames 0))
           (loop until (or (and frame-limit (>= frames frame-limit))
                           (lab.raylib:should-close-p))
                 do (update-world world)
                    (render-world world)
                    (incf frames))
           (when frame-limit
             (assert (= frames frame-limit))
             (format t "~&Rendered ~D frames successfully.~%" frames)))
      (lab.raylib:close-window))))
