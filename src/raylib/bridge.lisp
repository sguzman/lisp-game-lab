(in-package #:lab.raylib)

(defvar *bridge-loaded-p* nil)

(defun load-bridge (pathname)
  "Load the native bridge once; callers supply an explicit path."
  (unless *bridge-loaded-p*
    (sb-alien:load-shared-object (truename pathname))
    (setf *bridge-loaded-p* t))
  (unless (= 2 (abi-version))
    (error "Incompatible Raylib bridge ABI."))
  t)

(sb-alien:define-alien-routine ("lab_abi_version" abi-version) sb-alien:int)

(sb-alien:define-alien-routine ("lab_open" %open) sb-alien:int
  (width sb-alien:int) (height sb-alien:int) (title sb-alien:c-string))

(sb-alien:define-alien-routine ("lab_close" close-window) sb-alien:void)
(sb-alien:define-alien-routine ("lab_should_close" %should-close) sb-alien:int)
(sb-alien:define-alien-routine ("lab_input_x" input-x) sb-alien:int)
(sb-alien:define-alien-routine ("lab_input_y" input-y) sb-alien:int)
(sb-alien:define-alien-routine ("lab_begin" begin-frame) sb-alien:void)
(sb-alien:define-alien-routine ("lab_end" end-frame) sb-alien:void)

(sb-alien:define-alien-routine ("lab_draw_item" draw-item) sb-alien:void
  (x sb-alien:int) (y sb-alien:int) (size sb-alien:int))

(sb-alien:define-alien-routine ("lab_draw_label" draw-label) sb-alien:void
  (label sb-alien:c-string))

(defun open-window (width height title)
  (unless (= 1 (%open width height title))
    (error "Raylib failed to initialize a window."))
  t)

(defun should-close-p ()
  (not (zerop (%should-close))))

(sb-alien:define-alien-routine ("lab_load_texture" %load-texture)
    sb-alien:system-area-pointer
  (path sb-alien:c-string))

(sb-alien:define-alien-routine ("lab_unload_texture" unload-texture) sb-alien:void
  (handle sb-alien:system-area-pointer))

(sb-alien:define-alien-routine ("lab_draw_texture" draw-texture) sb-alien:void
  (handle sb-alien:system-area-pointer)
  (x sb-alien:int) (y sb-alien:int) (scale sb-alien:int))

(defun load-texture (path)
  (let ((handle (%load-texture (namestring (truename path)))))
    (when (zerop (sb-sys:sap-int handle))
      (error "Could not load texture ~A." path))
    handle))
