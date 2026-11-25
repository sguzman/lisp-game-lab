(require :asdf)
(asdf:load-asd (truename "lisp-game-lab.asd"))
(asdf:load-system "lisp-game-lab/live-assets")
(let* ((smoke (uiop:getenv "LAB_SMOKE"))
       (directory (merge-pathnames
                   (if smoke "build/assets-smoke/" "build/assets-live/")
                   (uiop:getcwd))))
  (lab.live-assets:run (uiop:getenv "LAB_RAYLIB_BRIDGE") directory :smoke smoke))
