(defpackage #:lab.audio
  (:use #:cl)
  (:export #:make-mixer #:mixer-volume #:mixer-muted-p #:mixer-ambience-p
           #:adjust-volume #:toggle-mute #:toggle-ambience #:gain))

(in-package #:lab.audio)

(defstruct mixer
  (volume 5 :type (integer 0 10))
  (muted-p nil)
  (ambience-p t))

(defun adjust-volume (mixer delta)
  (check-type delta integer)
  (setf (mixer-volume mixer) (max 0 (min 10 (+ (mixer-volume mixer) delta)))))

(defun toggle-mute (mixer)
  (setf (mixer-muted-p mixer) (not (mixer-muted-p mixer))))

(defun toggle-ambience (mixer)
  (setf (mixer-ambience-p mixer) (not (mixer-ambience-p mixer))))

(defun gain (mixer bus)
  "Independent relative bus gains under a common master setting."
  (let ((relative (ecase bus (:effects 0.8f0) (:ambience 0.35f0))))
    (if (mixer-muted-p mixer)
        0.0f0
        (* relative (/ (mixer-volume mixer) 10.0f0)))))
