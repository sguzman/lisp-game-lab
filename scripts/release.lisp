(require :asdf)
(asdf:load-asd (truename "lisp-game-lab.asd"))
(asdf:load-system "lisp-game-lab/release")
(assert (null (find-package :lab.console)))
(assert (null (find-package :lab.reload)))
(assert (null (find-package :lab.assets)))
;; Do not load the native library before saving: resolve it from the installed bundle.
(sb-ext:save-lisp-and-die
 (merge-pathnames #+win32 "build/release/lisp-game-lab.exe"
                  #-win32 "build/release/lisp-game-lab"
                  (uiop:getcwd))
 :toplevel #'lab.release:main :executable t :save-runtime-options t)
