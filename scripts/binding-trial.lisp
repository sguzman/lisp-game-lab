(require :asdf)
(asdf:load-asd (truename (uiop:getenv "LAB_TRIAL_GARBAGE")))
(asdf:load-asd (truename "raylib.asd"))
(asdf:load-system "raylib")

(sb-alien:define-alien-routine ("IsWindowReady" trial-window-ready-p)
    (boolean 8))

(defun run-binding-trial ()
  (raylib:init-window 320 240 "Binding compatibility trial")
  (unless (trial-window-ready-p)
    (error "The trial could not initialize a window."))
  (unwind-protect
       (let* ((texture (raylib:load-texture (truename (uiop:getenv "LAB_TRIAL_ASSET"))))
              (white (raylib:make-color :r 255 :g 255 :b 255 :a 255))
              (background (raylib:make-color :r 27 :g 33 :b 45 :a 255))
              (offset (raylib:make-vector2 :x 0 :y 0))
              (target (raylib:make-vector2 :x 16 :y 16))
              (camera (raylib:make-camera-2d :offset offset :target target
                                             :rotation 0 :zoom 1))
              (point (raylib:make-vector2 :x 64 :y 64)))
         (unwind-protect
              (progn
                (assert (raylib:is-texture-valid texture))
                (assert (= 32 (raylib:texture-width texture)
                           (raylib:texture-height texture)))
                (let ((screen (raylib:get-world-to-screen-2d point camera)))
                  (assert (= 48 (raylib:vector2-x screen)))
                  (assert (= 48 (raylib:vector2-y screen))))
                (raylib:set-target-fps 60)
                (dotimes (frame 3)
                  (when (raylib:window-should-close)
                    (error "Window closed before frame ~D." frame))
                  (raylib:is-key-down (raylib:keyboard-key :right))
                  (raylib:begin-drawing)
                  (unwind-protect
                       (progn
                         (raylib:clear-background background)
                         (raylib:begin-mode-2d camera)
                         (unwind-protect
                              (raylib:draw-texture texture 64 64 white)
                           (raylib:end-mode-2d)))
                    (raylib:end-drawing)))
                (format t "~&Binding trial: texture, camera, input query and 3 frames passed.~%"))
           (raylib:unload-texture texture)))
    (raylib:close-window)))

(run-binding-trial)
