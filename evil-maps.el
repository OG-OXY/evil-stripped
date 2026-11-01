;;; evil-maps.el --- Default keymaps -*- lexical-binding: t -*-

;; Author: Vegard Øye <vegard_oye at hotmail.com>
;; Maintainer: Vegard Øye <vegard_oye at hotmail.com>

;; Version: 1.15.0

;; This file is part of Evil.
;; (Neutralized for helix.el selection-first editing)

;;; Code:

(require 'evil-states)
(require 'evil-ex)
(require 'evil-commands)
(require 'evil-command-window)
(require 'evil-common)

;;; Normal state (Neutralized text edits; kept clean for helix.el)
(setq evil-normal-state-map (make-sparse-keymap))

;;; Visual state (Neutralized text edits; kept clean for helix.el)
(setq evil-visual-state-map (make-sparse-keymap))

;;; Operator-Pending state (Neutralized)
(setq evil-operator-state-map (make-sparse-keymap))

;;; Motion state (Neutralized text motions; kept window maps & tabs)
(setq evil-motion-state-map (make-sparse-keymap))

;; Keep window command map fully active so window splitting/switching works
(define-prefix-command 'evil-window-map)
(define-key evil-window-map "b" 'evil-window-bottom-right)
(define-key evil-window-map "c" 'evil-window-delete)
(define-key evil-window-map "f" 'ffap-other-window)
(define-key evil-window-map "h" 'evil-window-left)
(define-key evil-window-map "H" 'evil-window-move-far-left)
(define-key evil-window-map "j" 'evil-window-down)
(define-key evil-window-map "J" 'evil-window-move-very-bottom)
(define-key evil-window-map "k" 'evil-window-up)
(define-key evil-window-map "K" 'evil-window-move-very-top)
(define-key evil-window-map "l" 'evil-window-right)
(define-key evil-window-map "L" 'evil-window-move-far-right)
(define-key evil-window-map "n" 'evil-window-new)
(define-key evil-window-map "o" 'delete-other-windows)
(define-key evil-window-map "p" 'evil-window-mru)
(define-key evil-window-map "q" 'evil-quit)
(define-key evil-window-map "r" 'evil-window-rotate-downwards)
(define-key evil-window-map "R" 'evil-window-rotate-upwards)
(define-key evil-window-map "s" 'evil-window-split)
(define-key evil-window-map "S" 'evil-window-split)
(define-key evil-window-map "t" 'evil-window-top-left)
(when (featurep 'tab-bar)
  (define-key evil-window-map "T" 'tab-window-detach))
(define-key evil-window-map "v" 'evil-window-vsplit)
(define-key evil-window-map "w" 'evil-window-next)
(define-key evil-window-map "W" 'evil-window-prev)
(define-key evil-window-map "x" 'evil-window-exchange)
(define-key evil-window-map "+" 'evil-window-increase-height)
(define-key evil-window-map "-" 'evil-window-decrease-height)
(define-key evil-window-map ":" 'evil-ex)
(define-key evil-window-map "_" 'evil-window-set-height)
(define-key evil-window-map "<" 'evil-window-decrease-width)
(define-key evil-window-map ">" 'evil-window-increase-width)
(define-key evil-window-map "=" 'balance-windows)
(define-key evil-window-map (kbd "C-=") 'balance-windows)
(define-key evil-window-map "|" 'evil-window-set-width)

;; Bind window map prefix to C-w in motion state
(define-key evil-motion-state-map "\C-w" 'evil-window-map)

(when (featurep 'tab-bar)
  (define-key evil-motion-state-map "gt" 'evil-tab-next)
  (define-key evil-window-map "gt" 'evil-tab-next)
  (define-key evil-motion-state-map "gT" 'tab-bar-switch-to-prev-tab)
  (define-key evil-window-map "gT" 'tab-bar-switch-to-prev-tab))

;;; Insert state bindings (Kept clean for normal text insertion support)
(defvar evil-insert-state-bindings
  `(([insert] . evil-enter-replace-state)
    ("\C-q" . evil-quoted-insert)
    ("\C-v" . evil-quoted-insert)
    ("\C-k" . evil-insert-digraph)
    ("\C-o" . evil-execute-in-normal-state)
    ("\C-r" . evil-paste-from-register)
    ("\C-y" . evil-copy-from-above)
    ("\C-e" . evil-copy-from-below)
    ("\C-n" . evil-complete-next)
    ("\C-p" . evil-complete-previous)
    ("\C-t" . evil-shift-right-line)
    ("\C-d" . evil-shift-left-line)
    ("\C-a" . evil-paste-last-insertion)
    ([remap delete-backward-char] . evil-delete-backward-char-and-join)
    ("\C-w" . evil-window-map)
    ([mouse-2] . mouse-yank-primary))
  "Evil's bindings for insert state.")

(define-key evil-insert-state-map [delete] 'delete-char)
(define-key evil-insert-state-map [escape] 'evil-normal-state)

;;; Replace state
(setq evil-replace-state-map (make-sparse-keymap))
(define-key evil-replace-state-map [escape] 'evil-normal-state)

;;; Emacs state
(define-key evil-emacs-state-map
  (read-kbd-macro evil-toggle-key) 'evil-exit-emacs-state)

(when evil-want-C-w-in-emacs-state
  (define-key evil-emacs-state-map "\C-w" 'evil-window-map))

;;; Ex Commands (Kept intact for buffer management, files, and colon commands)
(define-key evil-motion-state-map ":" 'evil-ex)
(define-key evil-motion-state-map "!" 'evil-shell-command)

(evil-ex-define-cmd "e[dit]" 'evil-edit)
(evil-ex-define-cmd "vie[w]" 'evil-view)
(evil-ex-define-cmd "w[rite]" 'evil-write)
(evil-ex-define-cmd "up[date]" 'evil-update)
(evil-ex-define-cmd "wa[ll]" 'evil-write-all)
(evil-ex-define-cmd "sav[eas]" 'evil-save)
(evil-ex-define-cmd "r[ead]" 'evil-read)
(evil-ex-define-cmd "b[uffer]" 'evil-buffer)
(evil-ex-define-cmd "bad[d]" 'evil-buffer-add)
(evil-ex-define-cmd "bn[ext]" 'evil-next-buffer)
(evil-ex-define-cmd "bp[revious]" 'evil-prev-buffer)
(evil-ex-define-cmd "sb[uffer]" 'evil-split-buffer)
(evil-ex-define-cmd "buffers" 'buffer-menu)
(evil-ex-define-cmd "files" 'evil-show-files)
(evil-ex-define-cmd "ls" "buffers")
(evil-ex-define-cmd "sp[lit]" 'evil-window-split)
(evil-ex-define-cmd "vs[plit]" 'evil-window-vsplit)
(evil-ex-define-cmd "clo[se]" 'evil-window-delete)
(evil-ex-define-cmd "on[ly]" 'delete-other-windows)
(evil-ex-define-cmd "q[uit]" 'evil-quit)
(evil-ex-define-cmd "wq" 'evil-save-and-close)
(evil-ex-define-cmd "qa[ll]" "quitall")
(evil-ex-define-cmd "wqa[ll]" 'evil-save-and-quit)
(evil-ex-define-cmd "bd[elete]" 'evil-delete-buffer)

(when (featurep 'tab-bar)
  (evil-ex-define-cmd "tabnew" 'tab-bar-new-tab)
  (evil-ex-define-cmd "tabc[lose]" 'tab-bar-close-tab)
  (evil-ex-define-cmd "tabo[nly]" 'tab-bar-close-other-tabs)
  (evil-ex-define-cmd "tabn[ext]" 'evil-tab-next)
  (evil-ex-define-cmd "tabp[revious]" 'tab-bar-switch-to-prev-tab))

;; Command-line editing
(define-key evil-command-line-map "\d" #'evil-ex-delete-backward-char)
(define-key evil-command-line-map "\t" #'completion-at-point)
(define-key evil-command-line-map [tab] #'completion-at-point)

(provide 'evil-maps)

;;; evil-maps.el ends here
