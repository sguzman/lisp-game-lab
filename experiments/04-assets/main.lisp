(in-package #:lab.live-assets)

(defun fixture (name)
  (asdf:system-relative-pathname "lisp-game-lab" name))

(defun seed (target source smoke)
  (when (or smoke (not (probe-file target)))
    (lab.assets:write-bytes target (lab.assets:read-bytes source))))

(defun native-loader (scratch loader)
  ;; Load the exact observed snapshot, not a second read of the editable file.
  (lambda (bytes)
    (lab.assets:write-bytes scratch bytes)
    (funcall loader scratch)))

(defun report-poll (name slot)
  (multiple-value-bind (status diagnostic) (lab.assets:poll-asset slot)
    (unless (eq status :unchanged)
      (format t "~&Asset ~A ~A (revision ~D)~@[ -- ~A~]~%"
              name status (lab.assets:asset-slot-revision slot) diagnostic))
    status))

(defun draw-scene (world texture sound data)
  (lab.raylib:begin-frame)
  (unwind-protect
       (progn
         (destructuring-bind (x y) (lab.assets:asset-slot-value data)
           (lab.raylib:draw-item x y 64))
         (lab.raylib:draw-texture (lab.assets:asset-slot-value texture)
                                  (lab.core:world-x world)
                                  (lab.core:world-y world) 2)
         (lab.raylib:draw-label
          (format nil "04 | PNG ~A/~D WAV ~A/~D DATA ~A/~D"
                  (lab.assets:asset-slot-status texture)
                  (lab.assets:asset-slot-revision texture)
                  (lab.assets:asset-slot-status sound)
                  (lab.assets:asset-slot-revision sound)
                  (lab.assets:asset-slot-status data)
                  (lab.assets:asset-slot-revision data))))
    (lab.raylib:end-frame)))

(defun smoke-replace (frame directory)
  (flet ((put (name source)
           (lab.assets:write-bytes (merge-pathnames name directory)
                                   (lab.assets:read-bytes (fixture source))))
         (break-file (name)
           (lab.assets:write-bytes (merge-pathnames name directory)
                                   #(0 1 2 3))))
    (case frame
      (1 (put "sprite.png" "assets/02-rendering/plant.png")
       (put "effect.wav" "assets/04-assets/high.wav")
       (put "position.txt" "assets/04-assets/position-b.txt"))
      (2 (break-file "sprite.png")
       (break-file "effect.wav")
       (break-file "position.txt"))
      (3 (put "sprite.png" "assets/02-rendering/crate.png")
       (put "effect.wav" "assets/04-assets/low.wav")
       (put "position.txt" "assets/04-assets/position-a.txt")))))

(defun run (bridge directory &key smoke)
  (let* ((world (lab.core:make-world))
         (original world)
         (texture-path (merge-pathnames "sprite.png" directory))
         (sound-path (merge-pathnames "effect.wav" directory))
         (data-path (merge-pathnames "position.txt" directory))
         (texture (lab.assets:make-asset-slot
                   :path texture-path
                   :loader (native-loader (merge-pathnames "candidate.png" directory)
                                          #'lab.raylib:load-texture)
                   :disposer #'lab.raylib:unload-texture))
         (sound (lab.assets:make-asset-slot
                 :path sound-path
                 :loader (native-loader (merge-pathnames "candidate.wav" directory)
                                        #'lab.raylib:load-sound)
                 :disposer #'lab.raylib:unload-sound))
         (data (lab.assets:make-asset-slot
                :path data-path :loader #'lab.assets:parse-position
                :disposer (constantly nil)))
         (slots (list texture sound data)))
    (seed texture-path (fixture "assets/02-rendering/crate.png") smoke)
    (seed sound-path (fixture "assets/04-assets/low.wav") smoke)
    (seed data-path (fixture "assets/04-assets/position-a.txt") smoke)
    (format t "~&Live files: ~A~%Arrows move sprite; Space plays sound; Esc exits.~%"
            directory)
    (lab.raylib:with-graphics-float-environment
      (lab.raylib:load-bridge bridge)
      (lab.raylib:open-window lab.core:+width+ lab.core:+height+
                              "Lisp Game Lab | Live assets")
      (unwind-protect
           (progn
             (lab.raylib:open-audio)
             (unwind-protect
                  (let ((frames 0))
                    (loop until (or (and smoke (>= frames 4))
                                    (lab.raylib:should-close-p))
                          do (let ((old-values (mapcar #'lab.assets:asset-slot-value slots)))
                               (when smoke (smoke-replace frames directory))
                               (when (or smoke (zerop (mod frames 15)))
                                 (loop for name in '("PNG" "WAV" "DATA")
                                       for slot in slots
                                       for status = (report-poll name slot)
                                       do (unless (lab.assets:asset-slot-value slot)
                                            (error "No initial working ~A asset." name))
                                          (when smoke
                                            (assert (eq status
                                                        (if (= frames 2)
                                                            :rejected :accepted)))
                                            (assert (= (lab.assets:asset-slot-revision slot)
                                                       (case frames
                                                         (0 1) ((1 2) 2) (3 3)))))))
                               (when (and smoke (= frames 2))
                                 (assert (every #'eq old-values
                                                (mapcar #'lab.assets:asset-slot-value
                                                        slots)))))
                             (assert (eq original
                                         (lab.core:move-world
                                          world (if smoke 1 (* 4 (lab.raylib:input-x)))
                                          (if smoke 0 (* 4 (lab.raylib:input-y))))))
                             (when (or smoke (lab.raylib:sound-trigger-p))
                               (lab.raylib:play-sound (lab.assets:asset-slot-value sound)))
                             (draw-scene world texture sound data)
                             (incf frames))
                    (when smoke
                      (assert (= frames 4))
                      (format t "~&Asset smoke: 4 frames; PNG/WAV/data accepted, rejected and recovered.~%")))
               (unwind-protect
                    (dolist (slot slots) (lab.assets:close-asset slot))
                 (lab.raylib:close-audio))))
        (lab.raylib:close-window)))))
