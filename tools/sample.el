;;; sample.el --- A taste of Batppuccin -*- lexical-binding: t; -*-

;; This file exists only to show the theme off in screenshots.  It packs
;; a bit of everything the syntax highlighting touches: comments,
;; docstrings, strings, keywords, symbols, numbers, and a few defuns.

(require 'cl-lib)

(defgroup batppuccin-demo nil
  "A tiny group so the screenshot has a `defcustom' to color."
  :group 'faces)

(defcustom batppuccin-demo-greeting "Hello, Catppuccin!"
  "Text shown by `batppuccin-demo-say-hello'."
  :type 'string)

(defconst batppuccin-demo-flavors
  '((mocha     . "#1e1e2e")
    (macchiato . "#24273a")
    (frappe    . "#303446")
    (latte     . "#eff1f5"))
  "Base background color for each flavor.")

(defun batppuccin-demo-luminance (hex)
  "Return the relative luminance of HEX, a \"#rrggbb\" string."
  (cl-loop for i from 1 below 7 by 2
           for channel = (/ (string-to-number (substring hex i (+ i 2)) 16) 255.0)
           for weight in '(0.2126 0.7152 0.0722)
           sum (* weight (if (<= channel 0.03928)
                             (/ channel 12.92)
                           (expt (/ (+ channel 0.055) 1.055) 2.4)))))

(defun batppuccin-demo-say-hello (&optional name)
  "Greet NAME, defaulting to `user-login-name'."
  (interactive)
  (let ((who (or name user-login-name)))
    (message "%s (%s)" batppuccin-demo-greeting who)))

(provide 'sample)
;;; sample.el ends here
