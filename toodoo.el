(defvar toodoo-main-file "~/orgmode/todo_test.org")

;===============================================================================
;;; Core functions

(defun toodoo--todo-set-state-todo ()
  (interactive)
  (org-todo "TODO"))

(defun toodoo--todo-set-state-blocked ()
  (interactive)
  (org-todo "BLOCKED"))

(defun toodoo--todo-set-state-ongoing ()
  (interactive)
  (org-todo "ONGOING"))

(defun toodoo--todo-set-state-done ()
  (interactive)
  (org-todo "DONE"))

(defun toodoo--todo-set-state-clear ()
  (interactive)
  (org-todo ""))

(defun toodoo--manage-add (title)
  "Create a new Todo"
  (interactive "sTitle: ")
  (org-insert-heading-after-current)
  (insert title))

(defun toodoo--manage-edit ()
  "Edit a Todo"
  (interactive)
  (clone-indirect-buffer "*toodoo edit entry*" 1)
  (org-narrow-to-subtree)
  (toodoo-mode -1)
  (define-key evil-normal-state-map (kbd "q") 'kill-buffer-and-window))

(defun toodoo--manage-kill ()
  "Kill a todo."
  (interactive)
  (kill-whole-line))

;===============================================================================
;;; Operating Transient Menus

(define-transient-command toodoo-transient-state ()
  "Toodoo State Transient"
  ["State management"
   ("t" "Todo" toodoo--todo-set-state-todo)
   ("b" "Blocked" toodoo--todo-set-state-blocked)
   ("o" "Ongoing" toodoo--todo-set-state-ongoing)
   ("d" "Done" toodoo--todo-set-state-done)
   ("c" "Clear" toodoo--todo-set-state-clear)
   ])

(define-transient-command toodoo-transient-todos ()
  "Toodoo Add/Edit/Delete Transient"
  ["Actions"
   ("a" "Add" toodoo--manage-add)
   ("e" "Edit" toodoo--manage-edit)
   ("k" "Kill" toodoo--manage-kill)])

(define-transient-command toodoo-transient-main ()
  "Toodoo Main Transient"
  ["Actions"
   ("t" "Add/Edit/Delete Todos" toodoo-transient-todos)
   ("s" "State of Todos" toodoo-transient-state)])

;===============================================================================
;;; Toodoo Keymap setup

; define keymap for our mode and add in the keybindings
(defvar toodoo-mode-keymap (make-sparse-keymap))
(progn
  (define-key toodoo-mode-keymap (kbd "h") 'toodoo-transient-main)
  (define-key toodoo-mode-keymap (kbd "s") 'toodoo-transient-state)
  (define-key toodoo-mode-keymap (kbd "t") 'toodoo-transient-todos)
)

; This is needed to ensure that these keys take precedence over all other minor mode keybindings
; This is useful if not using evil-mode
; (add-to-list 'emulation-mode-map-alists '(toodoo-mode . toodoo-mode-keymap))

; This is needed to make evil respect our keymap
; we need our keys to override evil's
(evil-make-overriding-map toodoo-mode-keymap 'normal)
(add-hook 'toodoo-mode-hook #'evil-normalize-keymaps)

;===============================================================================
;;; Toodoo Minor Mode setup

;;;###autoload
(define-minor-mode toodoo-mode
  "Simple Todo management built on Org."
  :lighter " toodoo"
  :keymap toodoo-mode-keymap)

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
    (insert "#+TODO: TODO BLOCKED ONGOING DONE\n")
    (insert "* Today\n")
    (insert "* This Week\n")
    (insert "* Everything\n")))
