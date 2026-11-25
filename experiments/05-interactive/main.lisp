(in-package #:lab.interactive)

(defun draw-world (world count status)
  (lab.raylib:begin-frame)
  (unwind-protect
       (progn
         (lab.raylib:draw-item (lab.core:world-x world)
                              (lab.core:world-y world)
                              lab.core:+item-size+)
         (lab.raylib:draw-label
          (format nil "05 | Commands ~D | ~A | x=~D y=~D"
                  count status (lab.core:world-x world) (lab.core:world-y world))))
    (lab.raylib:end-frame)))

(defun report-result (status result)
  (let ((*print-circle* t)
        (*print-level* 5)
        (*print-length* 20))
    (format t "~&~A: ~S~%lab> " status result)
    (finish-output)))

(defun smoke-input ()
  (make-string-input-stream
   (format nil "(state)~%(move 100 20)~%(error \"intentional test\")~%(teleport 448 238)~%(quit)~%")))

(defun run (bridge &key smoke (input *standard-input*))
  (let* ((world (lab.core:make-world))
         (original world)
         (queue (lab.console:make-command-queue))
         (session (lab.console:make-session :world world))
         (reader nil)
         (count 0)
         (status :ready)
         (results nil)
         (frames 0))
    (lab.raylib:with-graphics-float-environment
      (lab.raylib:load-bridge bridge)
      (lab.raylib:open-window lab.core:+width+ lab.core:+height+
                              "Lisp Game Lab | Interactive console")
      (unwind-protect
           (progn
             (format t "~&Local Lisp console. (state), (move 100 0), (teleport 100 100), (quit).~%lab> ")
             (finish-output)
             (setf reader (lab.console:start-reader queue (if smoke (smoke-input) input)))
             (loop until (or (lab.console:session-stopping-p session)
                             (lab.raylib:should-close-p)
                             (and smoke (>= frames 180)))
                   do (let ((command (lab.console:dequeue queue)))
                        (when command
                          (multiple-value-bind (outcome value)
                              (lab.console:evaluate-line session command)
                            (setf status outcome)
                            (incf count)
                            (when smoke (push outcome results))
                            (report-result outcome value))))
                      (unless smoke
                        (lab.core:move-world world (* 4 (lab.raylib:input-x))
                                             (* 4 (lab.raylib:input-y))))
                      (draw-world world count status)
                      (incf frames))
             (when smoke
               (assert (lab.console:session-stopping-p session))
               (assert (= count 5))
               (assert (equal (reverse results) '(:ok :ok :error :ok :ok)))
               (assert (eq world original))
               (assert (= 448 (lab.core:world-x world)))
               (assert (= 238 (lab.core:world-y world)))
               (format t "~&Console smoke: 5 queued commands, error recovery, state preserved, quit processed.~%")))
        (unwind-protect
             (lab.console:stop-reader queue reader)
          (lab.raylib:close-window))))))
