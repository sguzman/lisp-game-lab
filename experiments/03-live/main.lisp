(in-package #:lab.live)

(defun write-source (path source &key (if-exists :supersede))
  (ensure-directories-exist path)
  (with-open-file (stream path :direction :output :if-exists if-exists
                              :if-does-not-exist :create)
    (when stream (write-line source stream))))

(defun report-reload (reloader path)
  (multiple-value-bind (status diagnostic)
      (lab.reload:poll-source reloader path)
    (unless (eq status :unchanged)
      (format t "~&Reload ~A (revision ~D)~@[ — ~A~]~%"
              status (lab.reload:reloader-revision reloader) diagnostic))
    status))

(defun step-world (world reloader dx dy)
  (multiple-value-bind (mx my)
      (lab.reload:movement-deltas reloader dx dy)
    (lab.core:move-world world mx my)))

(defun draw-world (world reloader)
  (lab.raylib:begin-frame)
  (unwind-protect
       (progn
         (lab.raylib:draw-item (lab.core:world-x world)
                              (lab.core:world-y world)
                              lab.core:+item-size+)
         (lab.raylib:draw-label
          (format nil "03 | Revision ~D | ~A | x=~D y=~D"
                  (lab.reload:reloader-revision reloader)
                  (lab.reload:reloader-status reloader)
                  (lab.core:world-x world) (lab.core:world-y world))))
    (lab.raylib:end-frame)))

(defun smoke-step (frame path world original reloader)
  (let ((old-x (lab.core:world-x world)))
    (case frame
      (0 (write-source path (lab.reload:default-source)))
      (1 (write-source path "(lambda (dx dy) (values (* 12 dx) (* 12 dy)))"))
      (2 (write-source path "(lambda (dx dy)"))
      (3 (write-source path "(lambda (dx dy) (values (* 2 dx) (* 2 dy)))")))
    (assert (eq (report-reload reloader path)
                (if (= frame 2) :rejected :accepted)))
    (assert (eq original (step-world world reloader 1 0)))
    (assert (= (lab.core:world-x world)
               (+ old-x (case frame (0 4) ((1 2) 12) (3 2)))))
    (assert (= (lab.reload:reloader-revision reloader)
               (case frame (0 1) ((1 2) 2) (3 3))))))

(defun run (bridge path &key smoke)
  (let* ((world (lab.core:make-world))
         (original world)
         (reloader (lab.reload:make-reloader)))
    (unless smoke
      (write-source path (lab.reload:default-source) :if-exists nil)
      (format t "~&Edit ~A while this window runs. Arrow keys move; Esc exits.~%"
              path)
      (report-reload reloader path))
    (lab.raylib:with-graphics-float-environment
      (lab.raylib:load-bridge bridge)
      (lab.raylib:open-window lab.core:+width+ lab.core:+height+
                              "Lisp Game Lab | Live code")
      (unwind-protect
           (let ((frames 0))
             (loop until (or (and smoke (>= frames 4))
                             (lab.raylib:should-close-p))
                   do (if smoke
                          (smoke-step frames path world original reloader)
                          (progn
                            (when (zerop (mod frames 15))
                              (report-reload reloader path))
                            (step-world world reloader
                                        (lab.raylib:input-x)
                                        (lab.raylib:input-y))))
                      (draw-world world reloader)
                      (incf frames))
             (when smoke
               (assert (= frames 4))
               (format t "~&Live smoke: 4 frames, accepted/rejected/recovered; world identity preserved.~%")))
        (lab.raylib:close-window)))))
