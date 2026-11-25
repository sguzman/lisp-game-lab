(asdf:defsystem "lisp-game-lab"
  :description "Headless game-domain primitives"
  :version "0.1.0"
  :license "MIT"
  :serial t
  :components ((:file "src/core/package")
               (:file "src/core/world")
               (:file "src/core/scene")
               (:file "src/core/objects")
               (:file "src/core/room")
               (:file "src/core/audio"))
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
  :depends-on ("lisp-game-lab" "lisp-game-lab/reload" "lisp-game-lab/asset-reload" "lisp-game-lab/console")
  :serial t
  :components ((:file "tests/package")
               (:file "tests/scene")
               (:file "tests/reload")
               (:file "tests/assets")
               (:file "tests/console")
               (:file "tests/objects")
               (:file "tests/room")
               (:file "tests/audio")
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

(asdf:defsystem "lisp-game-lab/asset-reload"
  :description "Headless asset replacement protocol"
  :components ((:file "src/dev/assets")))

(asdf:defsystem "lisp-game-lab/live-assets"
  :description "Live texture, sound and data experiment"
  :depends-on ("lisp-game-lab" "lisp-game-lab/raylib" "lisp-game-lab/asset-reload")
  :serial t
  :components ((:file "experiments/04-assets/package")
               (:file "experiments/04-assets/main")))

(asdf:defsystem "lisp-game-lab/console"
  :description "Opt-in local terminal evaluator and bounded command queue"
  :depends-on ("lisp-game-lab")
  :components ((:file "src/dev/console")))

(asdf:defsystem "lisp-game-lab/interactive"
  :description "Interactive development experiment"
  :depends-on ("lisp-game-lab" "lisp-game-lab/raylib" "lisp-game-lab/console")
  :serial t
  :components ((:file "experiments/05-interactive/package")
               (:file "experiments/05-interactive/main")))

(asdf:defsystem "lisp-game-lab/objects"
  :description "Deterministic object placement playground"
  :depends-on ("lisp-game-lab" "lisp-game-lab/raylib")
  :serial t
  :components ((:file "experiments/06-objects/package")
               (:file "experiments/06-objects/main")))

(asdf:defsystem "lisp-game-lab/rooms"
  :description "Declarative scene reload experiment"
  :depends-on ("lisp-game-lab/objects" "lisp-game-lab/asset-reload")
  :serial t
  :components ((:file "experiments/07-rooms/package")
               (:file "experiments/07-rooms/main")))

(asdf:defsystem "lisp-game-lab/audio"
  :description "Effects and streaming ambience experiment"
  :depends-on ("lisp-game-lab" "lisp-game-lab/raylib")
  :serial t
  :components ((:file "experiments/08-audio/package")
               (:file "experiments/08-audio/main")))
