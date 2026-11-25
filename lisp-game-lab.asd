(asdf:defsystem "lisp-game-lab"
  :description "Headless game-domain primitives"
  :version "0.1.0"
  :license "MIT"
  :serial t
  :components ((:file "src/core/package")
               (:file "src/core/world"))
  :in-order-to ((asdf:test-op (asdf:test-op "lisp-game-lab/tests"))))

(asdf:defsystem "lisp-game-lab/raylib"
  :description "SBCL adapter to the small Raylib ABI bridge"
  :serial t
  :components ((:file "src/raylib/package")
               (:file "src/raylib/bridge")))

(asdf:defsystem "lisp-game-lab/playground"
  :description "First interactive experiment"
  :depends-on ("lisp-game-lab" "lisp-game-lab/raylib")
  :serial t
  :components ((:file "experiments/01-playground/package")
               (:file "experiments/01-playground/main")))

(asdf:defsystem "lisp-game-lab/tests"
  :depends-on ("lisp-game-lab")
  :serial t
  :components ((:file "tests/package")
               (:file "tests/world"))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :lab.tests :run-tests)))
