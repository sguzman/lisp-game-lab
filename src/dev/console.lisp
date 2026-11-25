(defpackage #:lab.console
  (:use #:cl)
  (:export #:make-command-queue #:enqueue #:dequeue #:close-queue
           #:queue-open-p #:start-reader #:stop-reader
           #:make-session #:session-stopping-p #:evaluate-line
           #:state #:move #:teleport #:quit))

(in-package #:lab.console)

(defstruct command-queue
  (lock (sb-thread:make-mutex :name "local command queue"))
  (entries nil)
  (capacity 64 :type (integer 1))
  (closed-p nil))

(defun queue-open-p (queue)
  (sb-thread:with-mutex ((command-queue-lock queue))
    (not (command-queue-closed-p queue))))

(defun enqueue (queue line)
  "Transfer a command string to the owner thread. Never block for capacity."
  (check-type line string)
  (sb-thread:with-mutex ((command-queue-lock queue))
    (unless (or (command-queue-closed-p queue)
                (>= (length (command-queue-entries queue))
                    (command-queue-capacity queue)))
      (setf (command-queue-entries queue)
            (nconc (command-queue-entries queue) (list (copy-seq line))))
      t)))

(defun dequeue (queue)
  (sb-thread:with-mutex ((command-queue-lock queue))
    (pop (command-queue-entries queue))))

(defun close-queue (queue)
  "Reject new submissions and cancel commands not yet executed."
  (sb-thread:with-mutex ((command-queue-lock queue))
    (prog1 (length (command-queue-entries queue))
      (setf (command-queue-closed-p queue) t
            (command-queue-entries queue) nil))))

(defun start-reader (queue input &optional (diagnostics *error-output*))
  "Only the reader thread accesses INPUT. It never reads or evaluates Lisp forms."
  (sb-thread:make-thread
   (lambda ()
     (let ((characters nil)
           (too-long nil))
       (labels ((finish-line ()
                  (cond
                    (too-long (format diagnostics "~&Console line exceeds 4096 characters.~%"))
                    (characters
                     (unless (enqueue queue (coerce (nreverse characters) 'string))
                       (format diagnostics "~&Console queue full or closed; command rejected.~%"))))
                  (setf characters nil too-long nil)))
         (handler-case
             (loop while (queue-open-p queue)
                   for character = (read-char-no-hang input nil :eof)
                   do (cond
                        ((eq character :eof)
                         (finish-line)
                         (return))
                        ((null character) (sleep 0.02))
                        ((char= character #\Newline) (finish-line))
                        (too-long nil)
                        ((>= (length characters) 4096)
                         (setf characters nil too-long t))
                        (t (push character characters))))
           (error (condition)
             (format diagnostics "~&Console input closed: ~A~%" condition))))))
   :name "local terminal reader"))

(defun stop-reader (queue reader)
  (close-queue queue)
  (when reader
    (when (eq :timeout (sb-thread:join-thread reader :timeout 2 :default :timeout))
      (error "Console reader did not stop within two seconds.")))
  t)

(defstruct session
  world
  (owner sb-thread:*current-thread*)
  (stopping-p nil))

(defvar *session* nil)

(defun current-session ()
  (unless (and *session*
               (eq sb-thread:*current-thread* (session-owner *session*)))
    (error "Console operations require the game owner thread."))
  *session*)

(defun state ()
  (let* ((session (current-session))
         (world (session-world session)))
    (list :x (lab.core:world-x world) :y (lab.core:world-y world)
          :running (not (session-stopping-p session)))))

(defun move (dx dy)
  (lab.core:move-world (session-world (current-session)) dx dy)
  (state))

(defun teleport (x y)
  (check-type x integer)
  (check-type y integer)
  (let ((world (session-world (current-session))))
    (move (- x (lab.core:world-x world)) (- y (lab.core:world-y world)))))

(defun quit ()
  (setf (session-stopping-p (current-session)) t)
  :stopping)

(defun evaluate-line (session line)
  "Evaluate one trusted local expression on the owner thread; return status and values."
  (unless (eq sb-thread:*current-thread* (session-owner session))
    (error "Only the game owner may evaluate commands."))
  (when (session-stopping-p session)
    (return-from evaluate-line (values :rejected "Session is stopping.")))
  (handler-case
      (let ((*session* session)
            (*read-eval* nil)
            (*package* (find-package :lab.console))
            (*readtable* (copy-readtable nil))
            (eof (gensym)))
        (with-input-from-string (stream line)
          (let ((form (read stream nil eof)))
            (when (or (eq form eof) (not (eq eof (read stream nil eof))))
              (error "Enter exactly one Lisp expression per line."))
            (values :ok (multiple-value-list (eval form))))))
    (error (condition)
      (values :error (princ-to-string condition)))))
