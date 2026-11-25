(defpackage #:lab.room
  (:use #:cl)
  (:export #:parse-room))

(in-package #:lab.room)

(defun bounded-list-p (form maximum)
  (let ((size (list-length form)))
    (and size (<= size maximum))))

(defun parse-item (form)
  (unless (and (listp form) (bounded-list-p form 10) (= (length form) 10)
               (eq (first form) :item))
    (error "Expected (:item id x y width height turn color stackable support)."))
  (destructuring-bind (tag id x y width height turn color stackable support) form
    (declare (ignore tag))
    (lab.objects:make-item :id id :x x :y y :width width :height height
                           :turn turn :color color :stackable-p stackable
                           :support support)))

(defun parse-room (bytes)
  "Read exactly one versioned data form, never evaluate it."
  (unless (<= 1 (length bytes) 16384)
    (error "Room description must contain 1 to 16384 bytes."))
  (unless (every (lambda (byte)
                   (or (member byte '(9 10 13)) (<= 32 byte 126)))
                 bytes)
    (error "Room description must be ASCII."))
  (let ((*read-eval* nil)
        (*package* (find-package :lab.room))
        (*readtable* (copy-readtable nil))
        (eof (gensym)))
    (with-input-from-string (stream (map 'string #'code-char bytes))
      (let ((form (read stream nil eof)))
        (unless (and (listp form) (bounded-list-p form 66)
                     (eq (first form) :room) (eql (second form) 1))
          (error "Expected (:room 1 ...), at most 64 items."))
        (unless (eq eof (read stream nil eof))
          (error "Expected exactly one room description."))
        (lab.objects:validate-items (mapcar #'parse-item (cddr form)))))))
