;;; multi-term-plus.el --- An extensions plug for multi-term  -*- lexical-binding: t; -*-

;; Copyright (C) 2016 Aborn Jiang

;; Author: Aborn Jiang <aborn.jiang@gmail.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.4") (cl-lib "0.5") (let-alist "1.0.3") (s "1.10.0"))
;; Keywords: leanote, note, markdown
;; Homepage: https://github.com/aborn/aborn-multi-term
;; URL: https://github.com/aborn/leanote-emacs

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; The multi-term-plus package is used as extension for multi-term mode.
;;
;; The leanote package provides follwoing features:
;; * multi-term-find               Fast switch when you open multi-terms.
;; * multi-term-kill-line          Smart kill-line in multi-term mode.
;; * Auto recover previous term buffers
;;
;; Usage:
;; see multi-term-config.el
;;
;; Optional
;; 

;;; Code:
(require 'multi-term)

(defvar multi-term-recover-alist '())

(defcustom multi-term-recovery-p t
  "Is need to recover previous term buffers when emacs bootup."
  :type 'boolean
  :group 'multi-term)

(defcustom multi-term-recover-alist-file "~/.multi-term-recover-alist"
  "Multi term alist save file."
  :type 'string
  :group 'multi-term)

(defun multi-term-is-at-end-line ()
  "Cursor is in last line."
  (equal (line-number-at-pos) (count-lines (point-min) (point-max))))

(defun multi-term-is-term-mode ()
  "Current is term-mode"
  (string= major-mode "term-mode"))

(defun multi-term-backward-char ()
  "Backward-char in term-mode. "
  (interactive)
  (if (not (multi-term-is-term-mode))
      (backward-char)
    (progn (if (not (multi-term-is-at-end-line))
               (backward-char)
             (progn (term-send-left)
                    (message "term-send-left"))))))

(defun multi-term-forward-char ()
  "Forward-char in term-mode."
  (interactive)
  (if (not (multi-term-is-term-mode))
      (forward-char)
    (progn (if (not (multi-term-is-at-end-line))
               (forward-char)
             (progn (term-send-right)
                    (message "term-send-right"))))))

(defun multi-term-move-beginning-of-line ()
  "Smart version of move-beginning-of-line in term-mode."
  (interactive)
  (if (not (multi-term-is-term-mode))
      (beginning-of-line)
    (if (not (multi-term-is-at-end-line))
        (beginning-of-line)
      (term-send-raw))))

(defun multi-term-kill-line ()
  "Smart kill-line in multi-term mode."
  (interactive)
  (if (and (eq 'term-mode major-mode)
           (multi-term-is-at-end-line))
      (term-send-raw-string "\C-k")
    (kill-line)))

(defun multi-term-delete-char ()
  "Delete char in term-mode"
  (interactive)
  (if (multi-term-is-at-end-line)
      (term-send-raw)
    (delete-char 1)))

(defun multi-term-expand-region ()
  "Wrap er/expand-region function in term-mode."
  (interactive)
  (er/expand-region 1))

(defun multi-term--buffer-name-list ()
  "Multi-term session list."
  (mapcar (lambda (elt)
            (save-current-buffer
              (set-buffer elt)
              (let (name)
                (setq name (format "%s@%s" (buffer-name elt) default-directory))
                (list name elt))))
          multi-term-buffer-list))

(defun multi-term-find ()
  "Find multi-term by name, and switch it!"
  (interactive)
  (let* ((collection nil)
         (key nil))
    (setq collection (multi-term--buffer-name-list))
    (setq key (completing-read "find multi-term by name: "
                               collection))
    (let ((buf (car (assoc-default key collection))))
      (when (bufferp buf)
        (message "switch to buffer %s" (buffer-name buf))
        (switch-to-buffer buf)))))

(defun multi-term-create (name)
  "Create new term `NAME'"
  (let ((old default-directory))
    (setq default-directory name)
    (message "old=%s dir=%s" old default-directory)
    (multi-term)))

(defun multi-term-get-recover-alist ()
  "Produce multi-term recover alist."
  (mapcar (lambda (elt)
            (save-current-buffer
              (set-buffer elt)
              (cons (buffer-name)  default-directory)))
          multi-term-buffer-list))

(defun multi-term-save-term-alist ()
  "Save multi-term-recover-alist to file."
  (aborn/log "save it")
  (setq multi-term-recover-alist (multi-term-get-recover-alist))
  (with-temp-buffer
    (insert
     ";; -*- mode: emacs-lisp -*-\n"
     ";; Opened multi-term alist used for recovery.\n")
    (prin1 `(setq multi-term-recover-alist ',multi-term-recover-alist)
           (current-buffer))
    (write-region (point-min) (point-max) multi-term-recover-alist-file nil
                  (unless arg 'quiet))))

(defun multi-term-recover-terms ()
  "Recover multi-term previous buffers."
  (when multi-term-recovery-p
    (message "recovery multi-term previous buffers.")
    (dolist (elt multi-term-recover-alist)
      (multi-term-create (cdr elt)))))

(defun multi-term-plus-init ()
  "Recover previous term sessions when emacs bootup."
  (add-hook 'kill-emacs-hook
            'multi-term-save-term-alist)
  (when (file-readable-p multi-term-recover-alist-file)
    (load-file multi-term-recover-alist-file))
  (multi-term-recover-terms)
  (message "multi-term-plus inited."))

(provide 'multi-term-plus)