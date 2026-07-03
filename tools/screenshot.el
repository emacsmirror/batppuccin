;;; screenshot.el --- clean frame for Batppuccin screenshots -*- lexical-binding: t; -*-

;; Loaded by tools/generate.sh inside a throwaway `emacs -Q' to render one
;; theme variant against a sample buffer, then publish the frame geometry so
;; the shell can capture just that window.  macOS only.

;; Parameters arrive through the environment:
;;   SHOT_THEME     theme to load, e.g. batppuccin-latte
;;   SHOT_THEMEDIR  directory holding the theme files
;;   SHOT_FILE      sample source file to display
;;   SHOT_FONT      font family (optional; falls back to a sensible default)

(defvar shot-theme (intern (getenv "SHOT_THEME")))
(defvar shot-file (getenv "SHOT_FILE"))

(setq inhibit-startup-screen t
      initial-scratch-message nil
      ring-bell-function 'ignore
      make-backup-files nil
      use-dialog-box nil
      ;; Never block on file-local / dir-local variable prompts.
      enable-local-variables nil
      enable-dir-local-variables nil
      enable-local-eval nil)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode -1)
(setq-default cursor-type nil)          ; hide the cursor for a clean shot
(fringe-mode 8)

;; Pick the first available of a few nice monospace fonts.
(let ((font (or (getenv "SHOT_FONT")
                (seq-find (lambda (f) (member f (font-family-list)))
                          '("FiraCode Nerd Font" "Fira Code" "JetBrains Mono"
                            "Menlo"))
                "Menlo")))
  (set-face-attribute 'default nil :family font :height 150)
  (set-face-attribute 'fixed-pitch nil :family font :height 150))

;; Make the theme discoverable, then load it.
(let ((dir (getenv "SHOT_THEMEDIR")))
  (add-to-list 'load-path dir)
  (add-to-list 'custom-theme-load-path dir))
(load-theme shot-theme t)

(setq-default display-line-numbers-width 3)
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(show-paren-mode 1)
(setq show-paren-delay 0)

;; Fixed geometry, a title bar that matches the flavor's brightness, and a
;; frame that floats above other windows so the region capture grabs it.
(set-frame-size (selected-frame) 92 36)
(set-frame-position (selected-frame) 60 60)
(let ((appearance (if (string-match-p "day\\|latte\\|light" (symbol-name shot-theme))
                      'light 'dark)))
  (modify-frame-parameters
   (selected-frame)
   `((internal-border-width . 14)
     (line-spacing . 2)
     (z-group . above)
     (ns-transparent-titlebar . t)
     (ns-appearance . ,appearance))))

(when (and shot-file (file-exists-p shot-file))
  (find-file shot-file)
  (goto-char (point-min))
  (set-window-start (selected-window) (point-min)))

(defun shot-activate ()
  (when (fboundp 'ns-hide-emacs) (ns-hide-emacs 'activate))
  (raise-frame)
  (message nil)
  (redraw-display)                      ; clear any stale glyphs
  (redisplay t))
(shot-activate)

;; Publish the outer frame rect (points) and the background color, then a
;; readiness marker.  The capturer polls for the marker.
(defun shot-publish ()
  (let ((inhibit-message t) (message-log-max nil)
        (e (frame-edges (selected-frame) 'outer-edges)))
    (write-region (format "%s %s %s %s\n" (nth 0 e) (nth 1 e) (nth 2 e) (nth 3 e))
                  nil "/tmp/batppuccin-shot-geom.txt" nil)
    (write-region (format "%s\n" (face-background 'default))
                  nil "/tmp/batppuccin-shot-bg.txt" nil)
    (write-region "ready\n" nil "/tmp/batppuccin-shot-ready.txt" nil)))

(run-with-timer 1.2 nil (lambda () (shot-activate) (shot-publish)))

;;; screenshot.el ends here
