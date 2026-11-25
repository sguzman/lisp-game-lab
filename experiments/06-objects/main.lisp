(in-package #:lab.object-demo)

(defun update-board (board)
  (let ((x (lab.raylib:mouse-x))
        (y (lab.raylib:mouse-y)))
    (when (lab.raylib:mouse-pressed-p)
      (lab.objects:pick-item board x y))
    (when (lab.objects:board-held board)
      (lab.objects:drag-to board x y)
      (when (lab.raylib:rotate-pressed-p)
        (lab.objects:rotate-held board))
      (cond
        ((lab.raylib:cancel-pressed-p) (lab.objects:cancel-drag board))
        ((lab.raylib:mouse-released-p) (lab.objects:drop-held board))))))

(defun draw-board (board)
  (lab.raylib:begin-frame)
  (unwind-protect
       (progn
         (lab.raylib:draw-label "06 | Drag with mouse | R rotate | C cancel | Esc exit")
         (lab.raylib:draw-object-label
          (format nil "Placement: ~A | Brown/teal support stacks"
                  (lab.objects:board-status board)) 20 44)
         (dolist (item (lab.objects:draw-order board))
           (multiple-value-bind (w h) (lab.objects:dimensions item)
             (lab.raylib:draw-object
              (lab.objects:item-x item) (lab.objects:item-y item) w h
              (lab.objects:item-color item) (lab.objects:item-turn item)
              (if (eq item (lab.objects:board-held board)) 1 0))
             (lab.raylib:draw-object-label
              (format nil "~D~@[ on ~D~]" (lab.objects:item-id item)
                      (lab.objects:item-support item))
              (+ 14 (lab.objects:item-x item)) (+ 14 (lab.objects:item-y item))))))
    (lab.raylib:end-frame)))

(defun smoke-step (board frame)
  (let ((small (third (lab.objects:board-items board))))
    (case frame
      (0 (assert (eq small (lab.objects:pick-item board 550 160)))
       (lab.objects:drag-to board 180 200))
      (1 (lab.objects:rotate-held board)
       (lab.objects:drag-to board 180 200)
       (assert (eq small (lab.objects:drop-held board)))
       (assert (= 1 (lab.objects:item-support small)))
       (assert (= 1 (lab.objects:item-turn small))))
      (2 (assert (eq small (lab.objects:pick-item board 180 200)))
       (lab.objects:drag-to board -100 -100)
       (assert (null (lab.objects:drop-held board)))
       (assert (= 1 (lab.objects:item-support small)))
       (assert (eq :rejected (lab.objects:board-status board))))
      (3 (assert (eq small (lab.objects:pick-item board 180 200)))
       (lab.objects:drag-to board 650 330)
       (assert (eq small (lab.objects:drop-held board)))
       (assert (null (lab.objects:item-support small)))))))

(defun run (bridge &key smoke)
  (let ((board (lab.objects:make-demo-board)))
    (lab.raylib:with-graphics-float-environment
      (lab.raylib:load-bridge bridge)
      (lab.raylib:open-window lab.core:+width+ lab.core:+height+
                              "Lisp Game Lab | Object playground")
      (unwind-protect
           (let ((frames 0))
             (loop until (or (and smoke (>= frames 4))
                             (lab.raylib:should-close-p))
                   do (if smoke (smoke-step board frames) (update-board board))
                      (draw-board board)
                      (incf frames))
             (when smoke
               (assert (= frames 4))
               (format t "~&Object smoke: drag, rotate, stack, reject and detach passed.~%")))
        (lab.raylib:close-window)))))
