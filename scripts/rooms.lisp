(require :asdf)
(asdf:load-asd (truename "lisp-game-lab.asd"))
(asdf:load-system "lisp-game-lab/rooms")
(let* ((smoke (uiop:getenv "LAB_SMOKE"))
       (path (merge-pathnames
              (if smoke "build/room-smoke.room" "build/room-live.room")
              (uiop:getcwd))))
  (lab.room-demo:run (uiop:getenv "LAB_RAYLIB_BRIDGE") path :smoke smoke))
