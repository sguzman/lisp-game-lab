(in-package #:lab.tests)

(defun room-bytes (text)
  (map 'vector #'char-code text))

(defun test-room ()
  (let* ((initial "(:room 1 (:item 1 100 150 160 112 0 0 t nil) (:item 2 340 150 56 40 0 2 nil nil))")
         (changed "(:room 1 (:item 1 100 150 160 112 0 1 t nil) (:item 2 340 150 56 40 0 3 nil nil) (:item 3 50 340 80 40 0 2 nil nil))")
         (board (lab.objects:make-board)))
    (flet ((install (source)
             (lab.objects:migrate-items board (lab.room:parse-room (room-bytes source)))))
      (assert (eq board (install initial)))
      (let ((item (second (lab.objects:board-items board))))
        (assert (eq item (lab.objects:pick-item board 350 160)))
        (lab.objects:drag-to board 180 200)
        (lab.objects:rotate-held board)
        (assert (eq item (lab.objects:drop-held board)))
        (let ((x (lab.objects:item-x item)) (y (lab.objects:item-y item)))
          (assert (eq board (install changed)))
          (assert (eq item (second (lab.objects:board-items board))))
          (assert (= x (lab.objects:item-x item)))
          (assert (= y (lab.objects:item-y item)))
          (assert (= 1 (lab.objects:item-turn item)))
          (assert (= 1 (lab.objects:item-support item)))
          (assert (= 3 (lab.objects:item-color item)))
          (let ((old-items (lab.objects:board-items board)))
            (dolist (bad '("(:room 1 (:item 2 340 150 56 40 0 2 nil nil))"
                           "(:room 1 (:item 1 100 150 24 24 0 0 t nil) (:item 2 340 150 56 40 0 2 nil nil))"))
              (assert (handler-case (progn (install bad) nil) (error () t)))
              (assert (eq old-items (lab.objects:board-items board)))
              (assert (= 3 (lab.objects:item-color item)))))
          (assert (eq item (lab.objects:pick-item board 180 200)))
          (assert (handler-case (progn (install initial) nil) (error () t)))
          (lab.objects:cancel-drag board)
          (assert (eq board (install initial)))
          (assert (= 2 (length (lab.objects:board-items board))))
          (assert (eq item (second (lab.objects:board-items board))))
          (assert (= x (lab.objects:item-x item)))
          (assert (= y (lab.objects:item-y item)))))))
  (dolist (bad '("(:room 2)"
                 "(:room 1 (:item 1 0 0 32 32 0 0 nil nil))"
                 "(:room 1 (:item 1 100 100 32 32 0 0 nil 9))"
                 "(:room 1 (:item 1 100 100 32 32 0 0 t 2) (:item 2 100 100 32 32 0 0 t 1))"
                 "(:room 1 (:item 1 100 100 32 32 0 0 nil nil) (:item 1 200 200 32 32 0 0 nil nil))"
                 "(:room 1 (:item 1 100 100 32 32 0 0 nil nil) (:item 2 110 110 32 32 0 0 nil nil))"
                 "(:room 1 (:item 1 100 100 32 32 0 9 nil nil))"
                 "#.(error \"not evaluated\")"
                 "(:room 1) (:room 1)"
                 "#1=(:room 1 . #1#)"
                 "(:room 1 . 5)"))
    (assert (handler-case (progn (lab.room:parse-room (room-bytes bad)) nil)
              (error () t))))
  (format t "~&Room DSL validation, identity migration and atomic rejection tests passed.~%")
  t)
