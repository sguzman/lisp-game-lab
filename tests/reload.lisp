(in-package #:lab.tests)

(defun test-reload ()
  (let* ((reload (lab.reload:make-reloader))
         (world (lab.core:make-world))
         (original world))
    (flet ((step-right ()
             (multiple-value-bind (dx dy)
                 (lab.reload:movement-deltas reload 1 0)
               (assert (eq original (lab.core:move-world world dx dy))))))
      (step-right)
      (assert (= 372 (lab.core:world-x world)))
      (assert (lab.reload:install-source
               reload "(lambda (dx dy) (values (* 9 dx) (* 9 dy)))"))
      (step-right)
      (assert (= 381 (lab.core:world-x world)))
      (dolist (bad '("(lambda (dx dy)"
                     "(lambda (dx dy) (values dx dy)) nil"
                     "#.(error \"read-time evaluation\")"
                     "(lambda (dx dy) (values (/ dx 0) dy))"
                     "(lambda (dx dy) (values (* 100 dx) dy))"
                     "(lambda (dx dy) (values dx dy 0))"))
        (assert (not (lab.reload:install-source reload bad)))
        (assert (= 1 (lab.reload:reloader-revision reload)))
        (assert (eq :rejected (lab.reload:reloader-status reload))))
      (step-right)
      (assert (= 390 (lab.core:world-x world)))
      (assert (lab.reload:install-source
               reload "(lambda (dx dy) (values (* -2 dx) (* -2 dy)))"))
      (step-right)
      (assert (= 388 (lab.core:world-x world)))
      (assert (= 2 (lab.reload:reloader-revision reload)))
      ;; The candidate can pass preflight and fail later; do not mutate state
      ;; until a checked result is available. Exercise the defensive rollback.
      (let ((calls 0))
        (setf (lab.reload::reloader-previous reload)
              (lab.reload::reloader-active reload)
              (lab.reload::reloader-active reload)
              (lambda (dx dy)
                (declare (ignore dx dy))
                (incf calls)
                (error "Intentional runtime failure")))
        (step-right)
        (assert (= 386 (lab.core:world-x world)))
        (assert (= 1 calls))
        (assert (eq :rolled-back (lab.reload:reloader-status reload))))))
  (format t "~&Live reload acceptance and rollback tests passed.~%")
  t)
