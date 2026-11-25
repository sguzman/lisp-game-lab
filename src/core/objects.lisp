(defpackage #:lab.objects
  (:use #:cl)
  (:export #:item #:make-item #:item-id #:item-x #:item-y
           #:item-width #:item-height #:item-turn #:item-support
           #:item-stackable-p #:item-color #:dimensions
           #:make-board #:board-items #:board-held #:board-status
           #:pick-item #:drag-to #:rotate-held #:drop-held #:cancel-drag
           #:draw-order #:make-demo-board))

(in-package #:lab.objects)

(defstruct item
  id (x 0) (y 0) (width 80) (height 48) (turn 0)
  (stackable-p nil) (support nil) (color 0))

(defstruct board
  (items nil) (held nil) (snapshot nil)
  (offset-x 0) (offset-y 0)
  (status :ready))

(defun dimensions (item)
  (if (oddp (item-turn item))
      (values (item-height item) (item-width item))
      (values (item-width item) (item-height item))))

(defun overlaps-p (a b)
  (multiple-value-bind (aw ah) (dimensions a)
    (multiple-value-bind (bw bh) (dimensions b)
      (and (< (item-x a) (+ (item-x b) bw))
           (< (item-x b) (+ (item-x a) aw))
           (< (item-y a) (+ (item-y b) bh))
           (< (item-y b) (+ (item-y a) ah))))))

(defun contains-item-p (base top)
  (multiple-value-bind (bw bh) (dimensions base)
    (multiple-value-bind (tw th) (dimensions top)
      (and (<= (item-x base) (item-x top)
               (+ (item-x top) tw) (+ (item-x base) bw))
           (<= (item-y base) (item-y top)
               (+ (item-y top) th) (+ (item-y base) bh))))))

(defun in-bounds-p (item)
  (multiple-value-bind (w h) (dimensions item)
    (and (<= 0 (item-x item) (- lab.core:+width+ w))
         (<= 64 (item-y item) (- lab.core:+height+ h)))))

(defun child-of (board item)
  (find (item-id item) (board-items board) :key #'item-support :test #'eql))

(defun depth (board item)
  ;; Valid placements have only one parent per item and no cycles.
  (loop for parent = (item-support item)
          then (item-support (find parent (board-items board) :key #'item-id))
        while parent count parent))

(defun draw-order (board)
  (let ((held (board-held board)))
    (append (stable-sort (remove held (copy-list (board-items board)))
                         #'< :key (lambda (item) (depth board item)))
            (when held (list held)))))

(defun hit-p (item x y)
  (multiple-value-bind (w h) (dimensions item)
    (and (<= (item-x item) x) (< x (+ (item-x item) w))
         (<= (item-y item) y) (< y (+ (item-y item) h)))))

(defun pick-item (board x y)
  "Return the selected item, or NIL on an unsuccessful pickup."
  (unless (board-held board)
    (let ((item (find-if (lambda (i) (hit-p i x y))
                         (reverse (draw-order board)))))
      (cond
        ((null item)
         (setf (board-status board) :empty)
         nil)
        ((child-of board item)
         (setf (board-status board) :occupied)
         nil)
        (t
         (setf (board-held board) item
               (board-snapshot board)
               (list (item-x item) (item-y item) (item-turn item) (item-support item))
               (board-offset-x board) (- x (item-x item))
               (board-offset-y board) (- y (item-y item))
               (item-support item) nil
               (board-status board) :dragging)
         item)))))

(defun drag-to (board x y)
  (let ((item (board-held board)))
    (when item
      (setf (item-x item) (- x (board-offset-x board))
            (item-y item) (- y (board-offset-y board)))
      item)))

(defun rotate-held (board)
  (let ((item (board-held board)))
    (when item
      (multiple-value-bind (w h) (dimensions item)
        (let ((ox (board-offset-x board))
              (oy (board-offset-y board)))
          (declare (ignore w))
          ;; Clockwise quarter turn around the grabbed pixel.
          (setf (item-turn item) (mod (1+ (item-turn item)) 4)
                (board-offset-x board) (- h 1 oy)
                (board-offset-y board) ox)
          (incf (item-x item) (- ox (board-offset-x board)))
          (incf (item-y item) (- oy (board-offset-y board)))))
      item)))

(defun cancel-drag (board &optional (status :cancelled))
  (let ((item (board-held board)))
    (when item
      (destructuring-bind (x y turn support) (board-snapshot board)
        (setf (item-x item) x (item-y item) y
              (item-turn item) turn (item-support item) support))
      (setf (board-held board) nil (board-snapshot board) nil
            (board-status board) status)
      item)))

(defun ancestor-p (board ancestor item)
  (loop for parent = (item-support item)
          then (item-support (find parent (board-items board) :key #'item-id))
        while parent
        thereis (eql parent (item-id ancestor))))

(defun drop-held (board)
  (let ((item (board-held board)))
    (unless item (return-from drop-held nil))
    (unless (in-bounds-p item)
      (cancel-drag board :rejected)
      (return-from drop-held nil))
    (let* ((collisions
             (remove-if-not (lambda (other)
                              (and (not (eq other item)) (overlaps-p item other)))
                            (draw-order board)))
           (base (car (last collisions))))
      (unless (or (null collisions)
                  (and (item-stackable-p base)
                       (not (child-of board base))
                       (contains-item-p base item)
                       (every (lambda (other)
                                (or (eq other base) (ancestor-p board other base)))
                              collisions)))
        (cancel-drag board :rejected)
        (return-from drop-held nil))
      (setf (item-support item) (when base (item-id base))
            (board-held board) nil
            (board-snapshot board) nil
            (board-status board) (if base :stacked :placed))
      item)))

(defun make-demo-board ()
  (make-board
   :items (list (make-item :id 1 :x 100 :y 150 :width 160 :height 112
                            :stackable-p t :color 0)
                (make-item :id 2 :x 340 :y 150 :width 96 :height 56
                            :stackable-p t :color 1)
                (make-item :id 3 :x 540 :y 150 :width 56 :height 40
                            :color 2)
                (make-item :id 4 :x 340 :y 330 :width 112 :height 64
                            :color 3))))
