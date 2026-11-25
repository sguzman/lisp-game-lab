;; Batch style tooling. This is editor tooling, not game code.
(require 'cl-lib)
(require 'lisp-mode)

(let* ((format-p (equal (getenv "LAB_FORMAT") "1"))
       (files (cons "lisp-game-lab.asd"
                    (cl-mapcan
                     (lambda (dir)
                       (directory-files-recursively dir "\\.lisp\\'"))
                     '("src" "experiments" "tests" "scripts"))))
       (failed nil))
  (dolist (file files)
    (with-temp-buffer
      (insert-file-contents file)
      (lisp-mode)
      (setq indent-tabs-mode nil)
      (condition-case err
          (progn
            (check-parens)
            (if format-p
                (progn
                  (indent-region (point-min) (point-max))
                  (delete-trailing-whitespace)
                  (goto-char (point-max))
                  (unless (bolp) (insert "\n"))
                  (write-region (point-min) (point-max) file nil 'silent))
              (goto-char (point-min))
              (when (or (re-search-forward "\\(?:[ \t]+$\\|\t\\)" nil t)
                        (progn (goto-char (point-max)) (not (bolp))))
                (error "Tabs, trailing whitespace, or missing final newline"))))
        (error
         (setq failed t)
         (message "%s: %s" file (error-message-string err))))))
  (when failed (kill-emacs 1))
  (message "Lisp style/structure check complete"))
