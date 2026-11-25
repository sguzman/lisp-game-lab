(in-package #:lab.benchmarks)

(defun elapsed-ms (start)
  (* 1000.0d0 (/ (- (get-internal-real-time) start)
                 internal-time-units-per-second)))

(defun percentile (ordered fraction)
  (aref ordered (max 0 (1- (ceiling (* fraction (length ordered)))))))

(defun measure (name count thunk &key (warmup 3))
  (dotimes (i warmup) (funcall thunk))
  (sb-ext:gc :full t)
  (let ((samples (make-array count :element-type 'double-float))
        (before (sb-ext:get-bytes-consed)))
    (dotimes (i count)
      (let ((start (get-internal-real-time)))
        (funcall thunk)
        (setf (aref samples i) (elapsed-ms start))))
    (let ((bytes (- (sb-ext:get-bytes-consed) before))
          (ordered (sort samples #'<)))
      (format t "~&BENCH ~A n=~D median_ms=~,3F p95_ms=~,3F max_ms=~,3F allocated_bytes=~D~%"
              name count (percentile ordered 0.5d0) (percentile ordered 0.95d0)
              (aref ordered (1- count)) bytes))))

(defun room-bytes ()
  (lab.assets:read-bytes
   (asdf:system-relative-pathname "lisp-game-lab" "assets/07-rooms/initial.room")))

(defun run-headless ()
  (let ((reloader (lab.reload:make-reloader))
        (board (lab.objects:make-board))
        (bytes (room-bytes))
        (index 0))
    (format t "~&BENCH_ENV sbcl=~A machine=~A timer_hz=~D~%"
            (lisp-implementation-version) (machine-type) internal-time-units-per-second)
    (measure "code-reload" 50
             (lambda ()
               (assert (lab.reload:install-source
                        reloader (if (evenp (incf index))
                                     "(lambda (dx dy) (values (* 4 dx) (* 4 dy)))"
                                     "(lambda (dx dy) (values (* 5 dx) (* 5 dy)))")))))
    (measure "room-parse-migrate-4" 200
             (lambda ()
               (assert (eq board (lab.objects:migrate-items board (lab.room:parse-room bytes))))))
    (let ((slot (lab.assets:make-asset-slot :loader #'lab.assets:parse-position
                                           :disposer (constantly nil)))
          (position (map 'vector #'char-code "100 150")))
      (measure "asset-data-install" 200
               (lambda () (assert (eq :accepted (lab.assets:install-bytes slot position)))))
      (lab.assets:close-asset slot))
    (sb-ext:gc :full t)
    (format t "~&BENCH_HEAP after_full_gc_bytes=~D~%" (sb-kernel:dynamic-usage))))

(defun dense-board ()
  ;; 64 nonoverlapping 32x32 fixtures, deterministic grid, no random state.
  (lab.objects:make-board
   :items (loop for i below 64
                collect (lab.objects:make-item :id (1+ i)
                                               :x (+ 40 (* 80 (mod i 8)))
                                               :y (+ 76 (* 48 (floor i 8)))
                                               :width 32 :height 32 :color (mod i 4)))))

(defun frame-benchmark (board capped-p)
  (let ((frames 180)
        (samples (make-array 180 :element-type 'double-float)))
    (lab.raylib:target-fps (if capped-p 60 0))
    (dotimes (i 20) (lab.object-demo:draw-board board))
    (sb-ext:gc :full t)
    (let ((start (get-internal-real-time))
          (bytes (sb-ext:get-bytes-consed)))
      (dotimes (i frames)
        (when (lab.raylib:should-close-p) (error "Benchmark interrupted."))
        (let ((frame-start (get-internal-real-time)))
          (lab.object-demo:draw-board board :title "09 | Rendering benchmark"
                                     :subtitle "64 object fixtures")
          (setf (aref samples i) (elapsed-ms frame-start))))
      (let* ((ms (elapsed-ms start))
             (ordered (sort samples #'<)))
        (assert (plusp ms))
        (format t "~&BENCH frames-~A n=~D fps=~,2F median_ms=~,3F p95_ms=~,3F max_ms=~,3F allocated_bytes=~D~%"
                (if capped-p "60cap" "uncapped") frames (/ (* 1000.0d0 frames) ms)
                (percentile ordered 0.5d0) (percentile ordered 0.95d0)
                (aref ordered (1- frames)) (- (sb-ext:get-bytes-consed) bytes))))))

(defun run-graphics (bridge)
  (let ((board (dense-board)))
    (lab.objects:validate-items (lab.objects:board-items board))
    (lab.raylib:with-graphics-float-environment
      (lab.raylib:load-bridge bridge)
      (lab.raylib:open-window lab.core:+width+ lab.core:+height+ "Lisp Game Lab | Benchmark")
      (unwind-protect
           (progn
             (frame-benchmark board nil)
             (frame-benchmark board t)
             (sb-ext:gc :full t)
             (format t "~&BENCH_HEAP graphics_after_full_gc_bytes=~D~%" (sb-kernel:dynamic-usage)))
        (lab.raylib:close-window)))))
