;;; toodoo.el --- Magical interface to manage Todos on Org

;; Copyright (c) 2022 Chander Govindarajan <mail@chandergovind.org>

;; Author: Chander Govindarajan <mail@chandergovind.org>
;; Version: 0.2
;; Package-Requires: ((emacs "27.2") (transient "0.3.7"))
;; Keywords: calendar, convenience
;; URL: https://github.com/ChanderG/toodoo.el


;;; Commentary:

;; Provides a minor mode for fast and easy management of Todos using Org-mode and transients.

;;; Code:

;; File used to track tasks
(defvar toodoo-main-file "~/orgmode/todo.org")
;; Whether to base on evil. Set to 't' by default. Setting to nil, will make toodoo work with plain emacs.
(defvar toodoo-evil-base t)

;===============================================================================
;;; Core functions

(require 'org)
(require 'transient)
(if toodoo-evil-base
    (require 'evil))

(defun toodoo--todo-set-state-started ()
  "Set current entry to STARTED."
  (interactive)
  (org-todo "STARTED"))

(defun toodoo--todo-set-state-blocked ()
  "Set current entry to BLOCKED."
  (interactive)
  (org-todo "BLOCKED"))

(defun toodoo--todo-set-state-done ()
  "Set current entry to DONE."
  (interactive)
  (org-todo "DONE")
  (org-cycle))

(defun toodoo--todo-set-state-clear ()
  "Clear current entry to current state."
  (interactive)
  (org-todo ""))

; This function is a bit hacky in that we open up the entire file before adding things.
; The reason is that if this is not done, we end up with spurious empty lines at the end of the section.
(defun toodoo--manage-add (title)
  "Create a new Todo.
Argument TITLE - the title of the task"
  (interactive "sTitle: ")
  (widen) ; open up full file before adding stuff
  (org-insert-heading-after-current)
  (insert title)
  (if (= 1 (org-current-level))
     (org-demote))
  ; close back to the section - without losing point on current task
  (save-excursion
    (org-up-element)
    (org-narrow-to-subtree)))

;; Very hacky solution
;; The alternative (better) solution is to close the tree in the edit view
;; (since this function is called in that buffer's context.
;; But this does not work cleanly - leaving some text showing between the headlines due to the shared buffer.
(defun toodoo--close-edit-window-hook ()
  "Clean-up to be done on close of edit window."
  ; Find the main todo list buffer
  (with-current-buffer (find-file toodoo-main-file)
    ; go to the top of the file - the section marker
    (goto-char (point-min))
    ; force close the section
    (outline-hide-body)
    ; open it again
    (outline-show-children)))

(defun toodoo--manage-edit ()
  "Edit a Todo."
  (interactive)
  (clone-indirect-buffer "*toodoo edit entry*" 1)
  (org-narrow-to-subtree)
  (outline-show-subtree)
  (toodoo-mode -1)
  ;; provide a fast way to quit the edit buffer
  ;; in both cases - the keybinding is left in the global org-mode
  ;; either create a minor mode for this, or
  ;; hackliy remove these keybindings from the hook function
  (if toodoo-evil-base
    (define-key evil-normal-state-map (kbd "q") 'kill-buffer-and-window)
    (local-set-key (kbd "C-c q") 'kill-buffer-and-window))
  ;; Hack to reset the main window after edits are done
  (add-hook 'kill-buffer-hook 'toodoo--close-edit-window-hook 0 1))

(defun toodoo--manage-edit-title ()
  "Edit a Todo."
  (interactive)
  (org-edit-headline (read-string "Title: " (org-get-heading 1 1 1 1))))

(defun toodoo--manage-kill ()
  "Kill a todo."
  (interactive)
  (outline-hide-body)
  (kill-whole-line)
  ;; to avoid issues with empty lines at end of view
  (if (= (point) (point-max))
      (progn
        (widen)
        (kill-whole-line)
        (previous-line)
        ; close back to the section - without losing point on current task
        (save-excursion
          (org-up-element)
          (org-narrow-to-subtree))
        )))

(defun toodoo--get-section-heading ()
  "Get name of the current section."
  (interactive)
  (save-excursion
    (org-up-element)
    (substring-no-properties (org-get-heading 1 1 1 1))))

; This function is designed to move tasks between sections.
; However, it is more complicated than it should be to avoid spurious empty lines added
; between tasks. The ideas is to widen the file before attempting any refiles and finally
; reset the section view to what you started with.
(defun toodoo--todo-move-section (section)
  (interactive)
  (save-excursion
    (widen) ; first widen before moving
    (let ((home (toodoo--get-section-heading)))
      (org-refile nil nil (list section buffer-file-name nil (org-find-exact-headline-in-buffer section)))
      (toodoo--view-section home))))

(defun toodoo--todo-move-today ()
  "Move a Todo to Today's context."
  (interactive)
  (toodoo--todo-move-section "Today"))

(defun toodoo--todo-move-week ()
  "Move a Todo to this week's context."
  (interactive)
  (toodoo--todo-move-section "This Week"))

(defun toodoo--todo-move-later ()
  "Move a Todo to later's context."
  (interactive)
  (toodoo--todo-move-section "Later"))

(defun toodoo--todo-move-menu ()
  "Move a Todo to context using Menu."
  (interactive)
  (org-refile))

(defun toodoo--view-section (section)
  "View a single SECTION by Name."
  (interactive)
  (widen)
  (goto-char (point-min))
  (re-search-forward (concat "^* " section))
  (org-narrow-to-subtree)
  (outline-show-children))

(defun toodoo--view-today ()
  "View single section: Today."
  (interactive)
  (toodoo--view-section "Today"))

(defun toodoo--view-week ()
  "View single section: this Week."
  (interactive)
  (toodoo--view-section "This Week"))

(defun toodoo--view-later ()
  "View single section: Later."
  (interactive)
  (toodoo--view-section "Later"))

(defun toodoo--todo-set-prio-high ()
  "Set task to high priority."
  (interactive)
  (org-priority (org-priority-to-value "A")))

(defun toodoo--todo-set-prio-low ()
  "Set task to low priority."
  (interactive)
  (org-priority (org-priority-to-value " ")))

(defun toodoo--archive-everything ()
  "Archive all DONE entries."
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
(if toodoo-evil-base
  (progn
    (evil-make-overriding-map toodoo-mode-keymap 'normal)
    (add-hook 'toodoo-mode-hook #'evil-normalize-keymaps)))

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
  "Create the todo file, is used only for the initial setup."
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
