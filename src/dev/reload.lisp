(defpackage #:lab.reload
  (:use #:cl)
  (:export #:make-reloader #:reloader-revision #:reloader-status
           #:install-source #:poll-source #:movement-deltas
           #:default-source))

(in-package #:lab.reload)

(defun default-source ()
  "(lambda (dx dy) (values (* 4 dx) (* 4 dy)))")

(defun default-behavior (dx dy)
  (values (* 4 dx) (* 4 dy)))

(defstruct reloader
  (active #'default-behavior :type function)
  (previous #'default-behavior :type function)
  (revision 0 :type unsigned-byte)
  (status :ready)
  (observed nil))

(defun checked-deltas (behavior dx dy)
  (let ((result (multiple-value-list (funcall behavior dx dy))))
    (unless (and (= 2 (length result))
                 (every (lambda (n) (typep n '(integer -64 64))) result))
      (error "Movement must return exactly two integers in [-64,64]."))
    (values-list result)))

(defun compile-candidate (source)
  "Read and compile one trusted local lambda without replacing global functions."
  (let ((*read-eval* nil)
        (*package* (find-package :lab.reload))
        (*readtable* (copy-readtable nil))
        (eof (gensym)))
    (with-input-from-string (stream source)
      (let ((form (read stream nil eof)))
        (unless (and (consp form) (eq (first form) 'lambda)
                     (equal (second form) '(dx dy)))
          (error "Expected one (lambda (dx dy) ...) expression."))
        (unless (eq eof (read stream nil eof))
          (error "Expected exactly one expression."))
        (multiple-value-bind (candidate warnings-p failure-p)
            (compile nil form)
          (when (or warnings-p failure-p)
            (error "Candidate compilation produced warnings or errors."))
          ;; Validate the entire finite keyboard input domain before publication.
          (loop for dx from -1 to 1 do
            (loop for dy from -1 to 1 do
              (checked-deltas candidate dx dy)))
          candidate)))))

(defun install-source (reloader source)
  "Publish only a validated candidate; preserve the active function on error."
  (handler-case
      (let ((candidate (compile-candidate source)))
        (setf (reloader-previous reloader) (reloader-active reloader)
              (reloader-active reloader) candidate
              (reloader-status reloader) :accepted)
        (incf (reloader-revision reloader))
        (values t nil))
    (error (condition)
      (setf (reloader-status reloader) :rejected)
      (values nil (princ-to-string condition)))))

(defun read-source (path)
  (with-open-file (stream path :direction :input)
    (let ((source (make-string 16385)))
      (let ((count (read-sequence source stream)))
        (when (> count 16384)
          (error "Behavior source exceeds 16384 characters."))
        (subseq source 0 count)))))

(defun poll-source (reloader path)
  "Return :unchanged, :accepted, or :rejected and an optional diagnostic."
  (multiple-value-bind (source problem)
      (handler-case (values (read-source path) nil)
        (error (condition) (values nil (princ-to-string condition))))
    (let ((observation (if problem (list :error problem) (list :source source))))
      (when (equal observation (reloader-observed reloader))
        (return-from poll-source :unchanged))
      (setf (reloader-observed reloader) observation)
      (if problem
          (progn
            (setf (reloader-status reloader) :rejected)
            (values :rejected problem))
          (multiple-value-bind (accepted diagnostic)
              (install-source reloader source)
            (values (if accepted :accepted :rejected) diagnostic))))))

(defun movement-deltas (reloader dx dy)
  "Compute before mutating the world. Roll back a failing live behavior."
  (handler-case (checked-deltas (reloader-active reloader) dx dy)
    (error (condition)
      (setf (reloader-active reloader) (reloader-previous reloader)
            (reloader-previous reloader) #'default-behavior
            (reloader-status reloader) :rolled-back)
      (format *error-output* "~&Live behavior rolled back: ~A~%" condition)
      (handler-case (checked-deltas (reloader-active reloader) dx dy)
        (error ()
          (setf (reloader-active reloader) #'default-behavior)
          (default-behavior dx dy))))))
