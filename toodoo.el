;;; toodoo.el --- Magical interface to manage Todos on Org

;; Copyright (c) 2022 Chander Govindarajan <mail@chandergovind.org>

;; Author: Chander Govindarajan <mail@chandergovind.org>
;; Version: 0.1
;; Package-Requires: ((emacs "27.2") (transient "0.3.7") (evil "1.14.0"))
;; Keywords: calendar, convenience
;; URL: https://github.com/ChanderG/toodoo.el


;;; Commentary:

;; Provides a minor mode for fast and easy management of Todos using Org-mode and transients.

;;; Code:

(defvar toodoo-main-file "~/orgmode/todo.org")

;===============================================================================
;;; Core functions

(require 'org)
(require 'transient)
(require 'evil)

(defun toodoo--todo-set-state-started ()
  (interactive)
  (org-todo "STARTED"))

(defun toodoo--todo-set-state-blocked ()
  (interactive)
  (org-todo "BLOCKED"))

(defun toodoo--todo-set-state-done ()
  (interactive)
  (org-todo "DONE")
  (org-cycle))

(defun toodoo--todo-set-state-clear ()
  (interactive)
  (org-todo ""))

(defun toodoo--manage-add (title)
  "Create a new Todo"
  (interactive "sTitle: ")
  (org-insert-heading-after-current)
  (insert title)
  (if (= 1 (org-current-level))
    (org-demote)))

(defun toodoo--manage-edit ()
  "Edit a Todo"
  (interactive)
  (clone-indirect-buffer "*toodoo edit entry*" 1)
  (org-narrow-to-subtree)
  (outline-show-subtree)
  (toodoo-mode -1)
  (define-key evil-normal-state-map (kbd "q") 'kill-buffer-and-window))

(defun toodoo--manage-edit-title ()
  "Edit a Todo"
  (interactive)
  (org-edit-headline (read-string "Title: " (org-get-heading 1 1 1 1))))

(defun toodoo--manage-kill ()
  "Kill a todo."
  (interactive)
  (kill-whole-line))

(defun toodoo--todo-move-today ()
  "Move a Todo to Today's context."
  (interactive)
  (org-refile nil nil (list "Today" buffer-file-name nil (org-find-exact-headline-in-buffer "Today"))))

(defun toodoo--todo-move-week ()
  "Move a Todo to this week's context."
  (interactive)
  (org-refile nil nil (list "This Week" buffer-file-name nil (org-find-exact-headline-in-buffer "This Week"))))

(defun toodoo--todo-move-later ()
  "Move a Todo to later's context."
  (interactive)
  (org-refile nil nil (list "Later" buffer-file-name nil (org-find-exact-headline-in-buffer "Later"))))

(defun toodoo--todo-move-menu ()
  "Move a Todo to context using Menu."
  (interactive)
  (org-refile))

(defun toodoo--view-section (section)
  "View a single section by Name."
  (interactive)
  (widen)
  (goto-char (point-min))
  (re-search-forward (concat "^* " section))
  (org-narrow-to-subtree)
  (outline-show-children))

(defun toodoo--view-today ()
  "View single section: Today"
  (interactive)
  (toodoo--view-section "Today"))

(defun toodoo--view-week ()
  "View single section: this Week"
  (interactive)
  (toodoo--view-section "This Week"))

(defun toodoo--view-later ()
  "View single section: Later"
  (interactive)
  (toodoo--view-section "Later"))

(defun toodoo--todo-set-prio-high ()
  "Set task to high priority"
  (interactive)
  (org-priority (org-priority-to-value "A")))

(defun toodoo--todo-set-prio-low ()
  "Set task to low priority"
  (interactive)
  (org-priority (org-priority-to-value " ")))

(defun toodoo--archive-everything ()
  "Archive all DONE entries"
  (interactive)
  (save-restriction
    (widen)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^** DONE " nil 1)
        (org-archive-subtree)))))

;===============================================================================
;;; Operating Transient Menus

(define-transient-command toodoo-transient-archive ()
  "Toodoo Archive Transient"
  ["Archive"
   ("a" "Archive entry" org-archive-subtree)
   ("e" "Everything - all DONE entries" toodoo--archive-everything)])

(define-transient-command toodoo-transient-priority ()
  "Toodoo Priority Transient"
  ["Manage Priority"
   ("p" "High priority" toodoo--todo-set-prio-high)
   ("r" "Remove priority" toodoo--todo-set-prio-low)])

(define-transient-command toodoo-transient-views ()
  "Toodoo Views Transient"
  [["Section"
    ("t" "Today" toodoo--view-today)
    ("w" "this Week" toodoo--view-week)
    ("l" "Later" toodoo--view-later)]
   ["Combined"
    ()]
   ["All"
    ("a" "All" widen)]])

(define-transient-command toodoo-transient-move ()
  "Toodoo Move Transient"
  ["Move to Schedule"
   ("t" "Today" toodoo--todo-move-today)
   ("w" "this Week" toodoo--todo-move-week)
   ("l" "Later" toodoo--todo-move-later)
   ("m" "Chose from Menu" toodoo--todo-move-menu)])

(define-transient-command toodoo-transient-state ()
  "Toodoo State Transient"
  ["State management"
   ("s" "Started" toodoo--todo-set-state-started)
   ("b" "Blocked" toodoo--todo-set-state-blocked)
   ("d" "Done" toodoo--todo-set-state-done)
   ("c" "Clear" toodoo--todo-set-state-clear)
   ])

(define-transient-command toodoo-transient-todos ()
  "Toodoo Add/Edit/Delete Transient"
  [["Basic"
   ("a" "Add" toodoo--manage-add)
   ("e" "Edit" toodoo--manage-edit)
   ("k" "Kill" toodoo--manage-kill)]
  ["Advanced"
   ("t" "edit Title alone" toodoo--manage-edit-title)]])

(define-transient-command toodoo-transient-main ()
  "Toodoo Main Transient"
  [["List"
   ("t" "Manage (Add/Edit/Delete) todos" toodoo-transient-todos)
   ("m" "Move todos" toodoo-transient-move)
   ("v" "View" toodoo-transient-views)
   ("a" "Archive" toodoo-transient-archive)]
   ["Entry"
   ("s" "State of todos" toodoo-transient-state)
   ("p" "Priority" toodoo-transient-priority)]])

;===============================================================================
;;; Toodoo Keymap setup

; define keymap for our mode and add in the keybindings
(defvar toodoo-mode-keymap (make-sparse-keymap))
(progn
  (define-key toodoo-mode-keymap (kbd "h") 'toodoo-transient-main)
  (define-key toodoo-mode-keymap (kbd "s") 'toodoo-transient-state)
  (define-key toodoo-mode-keymap (kbd "t") 'toodoo-transient-todos)
  (define-key toodoo-mode-keymap (kbd "m") 'toodoo-transient-move)
  (define-key toodoo-mode-keymap (kbd "v") 'toodoo-transient-views)
  (define-key toodoo-mode-keymap (kbd "p") 'toodoo-transient-priority)
  (define-key toodoo-mode-keymap (kbd "a") 'toodoo-transient-archive))

; This is needed to ensure that these keys take precedence over all other minor mode keybindings
; This is useful if not using evil-mode
; (add-to-list 'emulation-mode-map-alists '(toodoo-mode . toodoo-mode-keymap))

; This is needed to make evil respect our keymap
; we need our keys to override evil's
; obtained from: https://github.com/emacs-evil/evil/issues/511#issuecomment-273754917
(evil-make-overriding-map toodoo-mode-keymap 'normal)
(add-hook 'toodoo-mode-hook #'evil-normalize-keymaps)


;===============================================================================
;;; Toodoo Minor Mode setup

;;;###autoload
(define-minor-mode toodoo-mode
  "Simple Todo management built on Org."
  :lighter " toodoo"
  :keymap toodoo-mode-keymap
  (if toodoo-mode
      ; commands to run on start up
      (progn
        (toodoo--view-today)
        ; highlight entries with priority [#A] considered as "high priority"
        (font-lock-add-keywords nil
                                '(("^.*\\[#A\\].*$" . 'org-date-selected))))
    ; commands to run on shutdown
    (progn
      ; remove highlight
      (font-lock-remove-keywords nil
                                 '(("^.*\\[#A\\].*$" . 'org-date-selected))))))

(provide 'toodoo-mode)


;===============================================================================
;;; Toodoo Startup functions

(defun toodoo-open-list ()
  "Open the main todo listing."
  (interactive)
  (if (not (file-exists-p toodoo-main-file))
    (toodoo--create-list))
  (find-file toodoo-main-file)
  (toodoo-mode 1))

(defun toodoo--create-list ()
  (with-temp-file toodoo-main-file
    ; setup the TODO color schemes using local variable
    (insert "# -*- org-todo-keyword-faces: ((\"BLOCKED\" . \"red\") (\"STARTED\" . (:foreground \"orange\" :underline t)) (\"DONE\" . \"darkgreen\")); -*-\n")
    (insert "#+TODO: BLOCKED STARTED DONE\n")
    ; to start with all headings closed
    (insert "#+STARTUP: overview\n")
    (insert "* Today\n")
    (insert "* This Week\n")
    (insert "* Later\n")))

(provide 'toodoo)

;;; toodoo.el ends here
