;;; evil-states.el --- States -*- lexical-binding: t -*-

;; Author: Vegard Øye <vegard_oye at hotmail.com>
;; Maintainer: Vegard Øye <vegard_oye at hotmail.com>

;; Version: 1.15.0

;;
;; This file is NOT part of GNU Emacs.

;;; License:

;; This file is part of Evil.
;;
;; Evil is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; Evil is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Evil.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'evil-core)

;;; Normal state

(evil-define-state normal
  "Normal state.
AKA \"Command\" state."
  :tag " <N> "
  :enable (motion)
  (cond
   ((evil-normal-state-p)
    (overwrite-mode -1)
    (add-hook 'post-command-hook #'evil-normal-post-command nil t))
   (t
    (remove-hook 'post-command-hook #'evil-normal-post-command t))))

(defun evil-normal-post-command (&optional command)
  "Reset command loop variables in Normal state.
Also prevent point from reaching the end of the line.
If the region is activated, enter Visual state."
  (unless (null this-command)
    (setq command (or command this-command))
    (when (evil-normal-state-p)
      (setq evil-this-type nil
            evil-this-operator nil
            evil-this-motion nil
            evil-this-motion-count nil
            evil-inhibit-operator nil
            evil-inhibit-operator-value nil)
      (unless (memq command '(evil-use-register
                              digit-argument
                              negative-argument
                              universal-argument
                              universal-argument-minus
                              universal-argument-more
                              universal-argument-other-key))
        (setq evil-this-register nil))
      (evil-adjust-cursor))))
(put 'evil-normal-post-command 'permanent-local-hook t)

;;; Insert state

(defun evil-maybe-remove-spaces (&optional do-remove)
  "Remove space from newly opened empty line.
This function removes (indentation) spaces that have been
inserted by opening a new empty line. The behavior depends on the
variable `evil-maybe-remove-spaces'. If this variable is nil the
function does nothing. Otherwise the behavior depends on
DO-REMOVE.  If DO-REMOVE is non-nil the spaces are
removed. Otherwise `evil-maybe-remove-spaces' is set to nil
unless the last command opened yet another new line.

This function should be added as a post-command-hook to track
commands opening a new line."
  (cond
   ((not evil-maybe-remove-spaces)
    (remove-hook 'post-command-hook #'evil-maybe-remove-spaces))
   (do-remove
    (when (save-excursion
            (beginning-of-line)
            (looking-at "^\\s-*$"))
      (delete-region (line-beginning-position)
                     (line-end-position)))
    (setq evil-maybe-remove-spaces nil)
    (remove-hook 'post-command-hook #'evil-maybe-remove-spaces))
   ((not (memq this-command
               '(evil-open-above
                 evil-open-below
                 evil-append
                 evil-append-line
                 evil-change-whole-line
                 newline
                 newline-and-indent
                 indent-and-newline)))
    (setq evil-maybe-remove-spaces nil)
    (remove-hook 'post-command-hook #'evil-maybe-remove-spaces))))

(evil-define-state insert
  "Insert state."
  :tag " <I> "
  :cursor (bar . 2)
  :message "-- INSERT --"
  :entry-hook (evil-start-track-last-insertion)
  :exit-hook (evil-cleanup-insert-state evil-stop-track-last-insertion)
  :input-method t
  (cond
   ((evil-insert-state-p)
    (add-hook 'post-command-hook #'evil-maybe-remove-spaces)
    (add-hook 'pre-command-hook #'evil-insert-repeat-hook)
    (setq evil-maybe-remove-spaces t)
    (unless (eq evil-want-fine-undo t)
      (evil-start-undo-step)))
   (t
    (remove-hook 'post-command-hook #'evil-maybe-remove-spaces)
    (remove-hook 'pre-command-hook #'evil-insert-repeat-hook)
    (evil-maybe-remove-spaces t)
    (setq evil-insert-repeat-info evil-repeat-info)
    (evil-set-marker ?^ nil t)
    (unless (eq evil-want-fine-undo t)
      (evil-end-undo-step))
    (when (or (evil-normal-state-p evil-next-state)
              (evil-motion-state-p evil-next-state))
      (evil-move-cursor-back
       (and (eolp) (not evil-move-beyond-eol)))))))

(defun evil-insert-repeat-hook ()
  "Record insertion keys in `evil-insert-repeat-info'."
  (setq evil-insert-repeat-info (last evil-repeat-info))
  (remove-hook 'pre-command-hook #'evil-insert-repeat-hook))
(put 'evil-insert-repeat-hook 'permanent-local-hook t)

(eval-when-compile
  ;; TODO remove this once support for emacs 26 is dropped
  (unless (fboundp 'combine-change-calls)
    (defmacro combine-change-calls (_beg _end &rest body) `(progn ,@body))))
(declare-function evil-execute-repeat-info "evil-repeat")
(defun evil-cleanup-insert-state ()
  "Called when Insert or Replace state is about to be exited.
Handles the repeat-count of the insertion command."
  (when evil-insert-count
    (let (pre-command-hook post-command-hook)
      (dotimes (_ (1- evil-insert-count))
        (when evil-insert-lines
          (evil-insert-newline-below)
          (when evil-auto-indent
            (indent-according-to-mode)))
        (evil-execute-repeat-info (cdr evil-insert-repeat-info)))))
  (when evil-insert-vcount
    (let ((buffer-invisibility-spec
           (if (listp buffer-invisibility-spec)
               ;; make all lines hidden by hideshow temporarily visible
               (cl-remove-if (lambda (x) (eq (or (car-safe x) x) 'hs))
                             buffer-invisibility-spec)
             buffer-invisibility-spec)))
      (cl-destructuring-bind (line col vcount) evil-insert-vcount
        (save-excursion
          (combine-change-calls ; For performance
              (progn (goto-char (point-min))
                     (line-beginning-position line))
              (line-end-position (+ line vcount -1))
            (let (pre-command-hook post-command-hook) ; For performance
              (dotimes (v (1- vcount))
                (goto-char (point-min))
                (forward-line (+ line v))
                (when (or (not evil-insert-skip-empty-lines)
                          (not (integerp col))
                          (save-excursion
                            (evil-move-end-of-line)
                            (>= (current-column) col)))
                  (if (integerp col)
                      (move-to-column col t)
                    (funcall col))
                  (dotimes (_ (or evil-insert-count 1))
                    (evil-execute-repeat-info (cdr evil-insert-repeat-info)))))))))))
  (and evil-want-fine-undo (evil-end-undo-step)))

;;; Visual state

;; Visual selections are implemented in terms of types, and are
;; compatible with the Emacs region. This is achieved by "translating"
;; the region to the selected text right before a command is executed.
;; If the command is a motion, the translation is postponed until a
;; non-motion command is invoked (distinguished by the :keep-visual
;; command property).
;;
;; Visual state activates the region, enabling Transient Mark mode if
;; not already enabled. This is only temporay: if Transient Mark mode
;; was disabled before entering Visual state, it is disabled when
;; exiting Visual state. This allows Visual state to harness the
;; "transient" behavior of many commands without overriding the user's
;; preferences in other states.
;;; Visual state (Neutralized for helix.el)

(defmacro evil-define-visual-selection (selection doc &rest body)
  "Stubbed out."
  (declare (indent defun) (doc-string 2))
  nil)

(evil-define-state visual
  "Visual state."
  :tag ""
  :enable nil
  :message nil
  nil)

(setq evil-visual-state-map (make-sparse-keymap))

(defun evil-visual-pre-command (&optional command) "Stubbed out." nil)
(defun evil-visual-post-command (&optional command) "Stubbed out." nil)
(defun evil-visual-update-x-selection (&optional buffer) "Stubbed out." nil)
(defun evil-visual-activate-hook (&optional _command) "Stubbed out." nil)
(defun evil-visual-deactivate-hook (&optional command) "Stubbed out." nil)

(evil-define-command evil-exit-visual-state (&optional later buffer)
  "Stubbed out."
  :keep-visual t
  :repeat abort
  nil)

(defun evil-visual-tag (&optional selection) "Stubbed out." nil)
(defun evil-visual-message (&optional selection) "Stubbed out." nil)
(defun evil-visual-select (beg end &optional type dir message) "Stubbed out." nil)
(defun evil-visual-make-selection (mark point &optional type message) "Stubbed out." nil)
(defun evil-visual-make-region (mark point &optional type message) "Stubbed out." nil)
(defun evil-visual-expand-region (&optional exclude-newline) "Stubbed out." nil)
(defun evil-visual-contract-region () "Stubbed out." nil)
(defun evil-visual-refresh (&optional mark point type &rest properties) "Stubbed out." nil)
(defun evil-visual-highlight (&optional arg) "Stubbed out." nil)
(defun evil-visual-highlight-block (beg end &optional overlays) "Stubbed out." nil)
(defun evil-visual-range () "Stubbed out." nil)
(defun evil-visual-direction () "Stubbed out." 1)
(defun evil-visual-type (&optional selection) "Stubbed out." nil)
(defun evil-visual-goto-end () "Stubbed out." nil)
(defun evil-visual-alist () "Stubbed out." nil)
(defun evil-visual-selection-function (selection) "Stubbed out." nil)
(defun evil-visual-selection-for-type (type) "Stubbed out." nil)
(defun evil-visual-block-corner (&optional corner point mark) "Stubbed out." 'upper-left)

;;; Operator-Pending state (Neutralized for helix.el)

(evil-define-state operator
  "Operator-Pending state."
  :tag ""
  :cursor nil
  :enable nil)

(setq evil-operator-state-map (make-sparse-keymap))

(evil-define-keymap evil-operator-shortcut-map
  "Stubbed out."
  :local t
  (setq evil-operator-shortcut-map (make-sparse-keymap))
  (evil-initialize-local-keymaps))

(defun evil-half-cursor ()
  "Stubbed out."
  nil)

;;; Replace state (Neutralized for helix.el)

(evil-define-state replace
  "Replace state."
  :tag ""
  :cursor nil
  :message nil
  nil)

(setq evil-replace-state-map (make-sparse-keymap))

(defun evil-replace-pre-command ()
  "Stubbed out."
  (interactive))

(defun evil-replace-backspace ()
  "Stubbed out."
  (interactive))

(defun evil-update-replace-alist (opoint count chars-to-delete &optional offset)
  "Stubbed out."
  nil)

;;; Motion state (Neutralized for helix.el)

(evil-define-state motion
  "Motion state."
  :tag ""
  :suppress-keymap nil)

(setq evil-motion-state-map (make-sparse-keymap))

;;; Emacs state (Neutralized for helix.el)

(evil-define-state emacs
  "Emacs state."
  :tag ""
  :message nil
  :input-method nil
  :intercept-esc nil)

(setq evil-emacs-state-map (make-sparse-keymap))

(provide 'evil-states)

;;; evil-states.el ends here
