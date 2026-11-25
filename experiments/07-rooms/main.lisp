(in-package #:lab.room-demo)

(defun fixture (name)
  (asdf:system-relative-pathname
   "lisp-game-lab" (format nil "assets/07-rooms/~A.room" name)))

(defun install-fixture (path name)
  (lab.assets:write-bytes path (lab.assets:read-bytes (fixture name))))

(defun lookup (board id)
  (find id (lab.objects:board-items board) :key #'lab.objects:item-id))

(defun report-poll (slot)
  (multiple-value-bind (status diagnostic) (lab.assets:poll-asset slot)
    (unless (eq status :unchanged)
      (format t "~&Room ~A (revision ~D)~@[ -- ~A~]~%"
              status (lab.assets:asset-slot-revision slot) diagnostic))
    status))

(defun smoke-step (frame path board slot)
  (case frame
    (0 (assert (eq :accepted (report-poll slot))))
    (1 (let ((item (lookup board 3)))
         (assert (eq item (lab.objects:pick-item board 550 160)))
         (lab.objects:drag-to board 660 340)
         (assert (eq item (lab.objects:drop-held board)))
         (install-fixture path "changed")
         (assert (eq :accepted (report-poll slot)))
         (assert (eq item (lookup board 3)))
         (assert (= 650 (lab.objects:item-x item)))
         (assert (= 330 (lab.objects:item-y item)))
         (assert (= 3 (lab.objects:item-color item)))
         (assert (lookup board 5))
         (assert (null (lookup board 4)))))
    (2 (let ((items (lab.objects:board-items board)))
         (install-fixture path "conflict")
         (assert (eq :rejected (report-poll slot)))
         (assert (eq items (lab.objects:board-items board)))
         (assert (null (lookup board 6)))))
    (3 (install-fixture path "initial")
     (assert (eq :accepted (report-poll slot)))
     (assert (lookup board 4))
     (assert (null (lookup board 5)))
     (assert (= 650 (lab.objects:item-x (lookup board 3))))
     (assert (= 2 (lab.objects:item-color (lookup board 3))))))
  (assert (eq board (lab.assets:asset-slot-value slot)))
  (assert (= (lab.assets:asset-slot-revision slot)
             (case frame (0 1) ((1 2) 2) (3 3)))))

(defun run (bridge path &key smoke)
  (let* ((board (lab.objects:make-board))
         (slot (lab.assets:make-asset-slot
                :path path
                :loader (lambda (bytes)
                          (lab.objects:migrate-items board (lab.room:parse-room bytes)))
                :disposer (constantly nil))))
    (when (or smoke (not (probe-file path)))
      (install-fixture path "initial"))
    (format t "~&Edit room file: ~A~%Reloads wait until a drag ends.~%" path)
    (unless smoke
      (unless (eq :accepted (report-poll slot))
        (error "No valid initial room. Restore initial.room and retry.")))
    (lab.raylib:with-graphics-float-environment
      (lab.raylib:load-bridge bridge)
      (lab.raylib:open-window lab.core:+width+ lab.core:+height+
                              "Lisp Game Lab | Declarative room")
      (unwind-protect
           (let ((frames 0))
             (loop until (or (and smoke (>= frames 4))
                             (lab.raylib:should-close-p))
                   do (if smoke
                          (smoke-step frames path board slot)
                          (progn
                            (lab.object-demo:update-board board)
                            (when (and (null (lab.objects:board-held board))
                                       (zerop (mod frames 15)))
                              (report-poll slot))))
                      (lab.object-demo:draw-board
                       board :title "07 | Live room | Drag | R rotate | C cancel"
                       :subtitle (format nil "Room ~A/~D | Placement ~A"
                                         (lab.assets:asset-slot-status slot)
                                         (lab.assets:asset-slot-revision slot)
                                         (lab.objects:board-status board)))
                      (incf frames))
             (when smoke
               (assert (= frames 4))
               (format t "~&Room smoke: migration, conflict rejection and recovery passed.~%")))
        (lab.assets:close-asset slot)
        (lab.raylib:close-window)))))
