(require :asdf)
(asdf:load-asd (truename "lisp-game-lab.asd"))
(asdf:load-system "lisp-game-lab/live")
(let* ((smoke (uiop:getenv "LAB_SMOKE"))
       (path (merge-pathnames
              (if smoke "build/live-smoke-behavior.lisp" "build/live-behavior.lisp")
              (uiop:getcwd))))
  (lab.live:run (uiop:getenv "LAB_RAYLIB_BRIDGE") path :smoke smoke))
