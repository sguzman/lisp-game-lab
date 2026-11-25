(require :asdf)
(asdf:load-asd (truename "lisp-game-lab.asd"))
(let ((start (get-internal-real-time)))
  (dolist (system '("playground" "rendering" "live" "live-assets" "interactive"
                    "objects" "rooms" "audio" "benchmarks"))
    (asdf:load-system (format nil "lisp-game-lab/~A" system)))
  (format t "~&BENCH_BUILD asdf_ms=~,3F cache=~A~%"
          (* 1000.0d0 (/ (- (get-internal-real-time) start)
                         internal-time-units-per-second))
          (uiop:getenv "XDG_CACHE_HOME")))
