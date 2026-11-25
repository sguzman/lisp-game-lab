(in-package #:lab.release)

(defun bundle-root ()
  (uiop:pathname-directory-pathname sb-ext:*core-pathname*))

(defun asset (name)
  (merge-pathnames name (bundle-root)))

(defun bridge-path ()
  (asset #+win32 "lab-raylib.dll"
         #+darwin "liblab-raylib.dylib"
         #-(or win32 darwin) "liblab-raylib.so"))

(defun self-test ()
  (assert (null (find-package :lab.console)))
  (assert (null (find-package :lab.reload)))
  (assert (null (find-package :lab.assets)))
  (assert (probe-file (asset "assets/ambience.wav")))
  (assert (probe-file (asset "assets/effect.wav")))
  (assert (lab.raylib:load-bridge (bridge-path)))
  (let ((board (lab.objects:make-demo-board)))
    (lab.objects:validate-items (lab.objects:board-items board))
    (assert (lab.objects:pick-item board 550 160))
    (lab.objects:drag-to board 180 200)
    (assert (lab.objects:drop-held board))
    (assert (eq :stacked (lab.objects:board-status board))))
  (format t "~&Release self-test passed: ABI ~D, assets, placement, no dev packages.~%"
          (lab.raylib:abi-version)))

(defun play-room (smoke audio-p)
  (let ((board (lab.objects:make-demo-board))
        (mixer (lab.audio:make-mixer))
        (sound nil)
        (music nil)
        (audio-open nil)
        (frames 0))
    (lab.raylib:with-graphics-float-environment
      (lab.raylib:load-bridge (bridge-path))
      (lab.raylib:open-window lab.core:+width+ lab.core:+height+
                              "Lisp Game Lab | Playable release")
      (unwind-protect
           (progn
             (when audio-p
               (lab.raylib:open-audio)
               (setf audio-open t
                     sound (lab.raylib:load-sound (asset "assets/effect.wav"))
                     music (lab.raylib:load-music (asset "assets/ambience.wav")))
               (lab.audio-demo:apply-gains mixer sound music)
               (lab.raylib:play-music music))
             (loop until (or (lab.raylib:should-close-p)
                             (and smoke (>= frames (if audio-p 180 4))))
                   do (cond
                        ((and smoke (zerop frames))
                         (assert (lab.objects:pick-item board 550 160))
                         (lab.objects:drag-to board 180 200)
                         (lab.objects:rotate-held board)
                         (assert (lab.objects:drop-held board))
                         (when sound (lab.raylib:play-sound sound)))
                        ((not smoke)
                         (let ((held (lab.objects:board-held board)))
                           (lab.object-demo:update-board board)
                           (when (and sound held (null (lab.objects:board-held board))
                                      (member (lab.objects:board-status board)
                                              '(:placed :stacked)))
                             (lab.raylib:play-sound sound)))
                         (when sound (lab.audio-demo:update-audio mixer sound music))))
                      (when (and music (lab.audio:mixer-ambience-p mixer))
                        (lab.raylib:update-music music))
                      (lab.object-demo:draw-board
                       board :title "Drag objects | R rotate | C cancel | M ambience | Esc exit"
                       :subtitle (format nil "~A | ~A | Volume ~D% (Up/Down, V mute)"
                                         (lab.objects:board-status board)
                                         (if audio-p "Audio enabled" "Silent smoke")
                                         (* 10 (lab.audio:mixer-volume mixer))))
                      (incf frames))
             (when smoke
               (assert (= frames (if audio-p 180 4)))
               (assert (eq :stacked (lab.objects:board-status board)))
               (when music (assert (lab.raylib:music-playing-p music)))
               (format t "~&Release graphical smoke passed: ~D frames, audio ~A.~%"
                       frames audio-p)))
        (unwind-protect
             (when audio-open
               (unwind-protect
                    (progn
                      (when sound
                        (lab.raylib:stop-sound sound)
                        (lab.raylib:unload-sound sound))
                      (when music
                        (lab.raylib:stop-music music)
                        (lab.raylib:unload-music music)))
                 (lab.raylib:close-audio)))
          (lab.raylib:close-window))))))

(defun main ()
  (sb-ext:disable-debugger)
  (handler-case
      (progn
        (let ((args (rest sb-ext:*posix-argv*)))
          (cond
            ((equal args '("--self-test")) (self-test))
            ((equal args '("--smoke")) (play-room t nil))
            ((equal args '("--audio-smoke")) (play-room t t))
            ((null args) (play-room nil t))
            (t (error "Usage: lisp-game-lab [--self-test | --smoke | --audio-smoke]"))))
        (sb-ext:exit :code 0))
    (error (condition)
      (format *error-output* "~&Release failed: ~A~%" condition)
      (sb-ext:exit :code 1))))
