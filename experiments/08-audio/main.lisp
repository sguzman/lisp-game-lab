(in-package #:lab.audio-demo)

(defun fixture (name)
  (asdf:system-relative-pathname "lisp-game-lab" name))

(defun apply-gains (mixer sound music)
  (lab.raylib:sound-volume sound (lab.audio:gain mixer :effects))
  (lab.raylib:music-volume music (lab.audio:gain mixer :ambience)))

(defun update-audio (mixer sound music)
  (let ((delta (lab.raylib:audio-volume-delta)))
    (unless (zerop delta) (lab.audio:adjust-volume mixer delta)))
  (when (lab.raylib:audio-mute-p) (lab.audio:toggle-mute mixer))
  (apply-gains mixer sound music)
  (when (lab.raylib:audio-toggle-p)
    (if (lab.audio:toggle-ambience mixer)
        (lab.raylib:play-music music)
        (lab.raylib:stop-music music)))
  (when (lab.raylib:sound-trigger-p)
    (lab.raylib:play-sound sound)))

(defun draw-audio (mixer music)
  (lab.raylib:begin-frame)
  (unwind-protect
       (progn
         (lab.raylib:draw-label "08 | Space: effect | M: ambience | V: mute | Up/Down: volume")
         (lab.raylib:draw-object-label
          (format nil "Volume ~D% | ~A | Ambience ~A | ~,2F / ~,2F sec"
                  (* 10 (lab.audio:mixer-volume mixer))
                  (if (lab.audio:mixer-muted-p mixer) "MUTED" "AUDIBLE")
                  (if (lab.audio:mixer-ambience-p mixer) "ON" "OFF")
                  (lab.raylib:music-time music) (lab.raylib:music-length music))
          20 52)
         (lab.raylib:draw-object 100 130 600 48 0 0 0)
         (let ((width (* 60 (lab.audio:mixer-volume mixer))))
           (when (plusp width)
             (lab.raylib:draw-object 100 130 width 48 1 0 0))))
    (lab.raylib:end-frame)))

(defun smoke-controls (frame mixer sound music)
  (case frame
    (0 (assert (lab.raylib:music-playing-p music))
       (assert (lab.raylib:music-looping-p music))
       (assert (> (lab.raylib:music-length music) 0.5f0))
       (lab.raylib:play-sound sound)
       (assert (lab.raylib:sound-playing-p sound)))
    (1 (lab.raylib:stop-sound sound)
       (assert (not (lab.raylib:sound-playing-p sound)))
       (lab.audio:adjust-volume mixer 3)
       (assert (= 8 (lab.audio:mixer-volume mixer)))
       (apply-gains mixer sound music))
    (2 (lab.audio:toggle-mute mixer)
       (apply-gains mixer sound music)
       (assert (zerop (lab.audio:gain mixer :ambience)))
       (assert (zerop (lab.audio:gain mixer :effects))))
    (3 (lab.audio:toggle-mute mixer)
       (apply-gains mixer sound music)
       (lab.audio:toggle-ambience mixer)
       (lab.raylib:stop-music music)
       (assert (not (lab.raylib:music-playing-p music))))
    (4 (lab.audio:toggle-ambience mixer)
       (lab.raylib:play-music music)
       (assert (lab.raylib:music-playing-p music)))))

(defun run (bridge &key smoke)
  (let ((mixer (lab.audio:make-mixer))
        (sound nil)
        (music nil)
        (frames 0)
        (last-time 0.0f0)
        (wraps 0)
        (advanced nil))
    (lab.raylib:with-graphics-float-environment
      (lab.raylib:load-bridge bridge)
      (lab.raylib:open-window lab.core:+width+ lab.core:+height+
                              "Lisp Game Lab | Audio")
      (unwind-protect
           (progn
             (lab.raylib:open-audio)
             (unwind-protect
                  (progn
                    (setf sound (lab.raylib:load-sound (fixture "assets/04-assets/high.wav"))
                          music (lab.raylib:load-music (fixture "assets/08-audio/ambience.wav")))
                    (apply-gains mixer sound music)
                    (lab.raylib:play-music music)
                    (loop until (or (lab.raylib:should-close-p)
                                    (and smoke (>= frames 300)))
                          do (if smoke
                                 (smoke-controls frames mixer sound music)
                                 (update-audio mixer sound music))
                             (when (lab.audio:mixer-ambience-p mixer)
                               (lab.raylib:update-music music))
                             (when (and smoke (> frames 4))
                               (let ((time (lab.raylib:music-time music)))
                                 (when (> time last-time) (setf advanced t))
                                 (when (< time (- last-time 0.3f0)) (incf wraps))
                                 (setf last-time time)))
                             (draw-audio mixer music)
                             (incf frames))
                    (when smoke
                      (assert (= frames 300))
                      (assert advanced)
                      (assert (plusp wraps))
                      (assert (lab.raylib:music-playing-p music))
                      (format t "~&Audio smoke: effects, mixer, stream advance, ~D loop wraps and restart passed.~%" wraps)))
               (unwind-protect
                    (progn
                      (when sound
                        (lab.raylib:stop-sound sound)
                        (lab.raylib:unload-sound sound))
                      (when music
                        (lab.raylib:stop-music music)
                        (lab.raylib:unload-music music)))
                 (lab.raylib:close-audio))))
        (lab.raylib:close-window)))))
