(asdf:defsystem "lisp-game-lab"
  :description "Headless game-domain primitives"
  :version "0.1.0"
  :license "MIT"
  :serial t
  :components ((:file "src/core/package")
               (:file "src/core/world")
               (:file "src/core/scene"))
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
  :depends-on ("lisp-game-lab" "lisp-game-lab/reload")
  :serial t
  :components ((:file "tests/package")
               (:file "tests/scene")
               (:file "tests/reload")
               (:file "tests/world"))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :lab.tests :run-tests)))

(asdf:defsystem "lisp-game-lab/rendering"
  :description "Layered sprite and camera experiment"
  :depends-on ("lisp-game-lab" "lisp-game-lab/raylib")
  :serial t
  :components ((:file "experiments/02-rendering/package")
               (:file "experiments/02-rendering/main")))

(asdf:defsystem "lisp-game-lab/reload"
  :description "Development-only transactional behavior replacement"
  :components ((:file "src/dev/reload")))

(asdf:defsystem "lisp-game-lab/live"
  :description "Live behavior experiment"
  :depends-on ("lisp-game-lab" "lisp-game-lab/raylib" "lisp-game-lab/reload")
  :serial t
  :components ((:file "experiments/03-live/package")
               (:file "experiments/03-live/main")))
