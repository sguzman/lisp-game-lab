(defpackage #:lab.assets
  (:use #:cl)
  (:export #:make-asset-slot #:asset-slot-value #:asset-slot-revision
           #:asset-slot-status #:install-bytes #:poll-asset #:close-asset
           #:read-bytes #:write-bytes #:parse-position))

(in-package #:lab.assets)

(defstruct asset-slot
  path
  loader
  disposer
  value
  (revision 0)
  (status :ready)
  observed)

(defun read-bytes (path)
  "Read a bounded byte snapshot; reject a file that changes length mid-read."
  (with-open-file (stream path :direction :input :element-type '(unsigned-byte 8))
    (let ((size (file-length stream)))
      (unless (<= 1 size 1048576)
        (error "Asset must contain 1 to 1048576 bytes."))
      (let ((bytes (make-array size :element-type '(unsigned-byte 8))))
        (unless (and (= size (read-sequence bytes stream))
                     (null (read-byte stream nil nil)))
          (error "Asset length changed while reading."))
        bytes))))

(defun write-bytes (path bytes)
  (ensure-directories-exist path)
  (with-open-file (stream path :direction :output :element-type '(unsigned-byte 8)
                              :if-exists :supersede :if-does-not-exist :create)
    (write-sequence bytes stream)))

(defun install-bytes (slot bytes)
  "Prepare before publishing. Disposers are required to be non-signaling."
  (multiple-value-bind (candidate diagnostic)
      (handler-case
          (let ((value (funcall (asset-slot-loader slot) bytes)))
            (unless value (error "Loader returned no resource."))
            (values value nil))
        (error (condition) (values nil (princ-to-string condition))))
    (if diagnostic
        (progn
          (setf (asset-slot-status slot) :rejected)
          (values :rejected diagnostic))
        (let ((old (asset-slot-value slot)))
          (setf (asset-slot-value slot) candidate
                (asset-slot-status slot) :accepted)
          (incf (asset-slot-revision slot))
          (when old (funcall (asset-slot-disposer slot) old))
          (values :accepted nil)))))

(defun poll-asset (slot)
  "Compare contents, not timestamps; do not repeat an unchanged rejection."
  (multiple-value-bind (bytes problem)
      (handler-case (values (read-bytes (asset-slot-path slot)) nil)
        (error (condition) (values nil (princ-to-string condition))))
    (let ((observation (if problem (list :error problem) (list :bytes bytes))))
      (when (equalp observation (asset-slot-observed slot))
        (return-from poll-asset :unchanged))
      (setf (asset-slot-observed slot) observation)
      (if problem
          (progn
            (setf (asset-slot-status slot) :rejected)
            (values :rejected problem))
          (install-bytes slot bytes)))))

(defun close-asset (slot)
  (when (asset-slot-value slot)
    (let ((old (asset-slot-value slot)))
      (setf (asset-slot-value slot) nil
            (asset-slot-observed slot) nil
            (asset-slot-status slot) :closed)
      (funcall (asset-slot-disposer slot) old))))

(defun parse-position (bytes)
  "A data-only format: two decimal integers, no Lisp reader or evaluation."
  (let* ((text (map 'string #'code-char bytes))
         (tokens (remove "" (uiop:split-string
                              text :separator '(#\Space #\Tab #\Newline #\Return))
                         :test #'string=)))
    (unless (= 2 (length tokens))
      (error "Expected two integer coordinates."))
    (destructuring-bind (x y) (mapcar #'parse-integer tokens)
      (unless (and (<= 0 x 736) (<= 64 y 416))
        (error "Position is outside the scene."))
      (list x y))))
