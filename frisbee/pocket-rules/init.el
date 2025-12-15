;;; init.el --- Aayush's config using straight.el -*- lexical-binding: t; -*-

;; Make sure package.el does not auto-enable (extra safety; main one is early-init)
(setq package-enable-at-startup nil)

;; ---------------------------------------------------------------------------
;; Bootstrap straight.el + use-package
;; ---------------------------------------------------------------------------
(defvar bootstrap-version)
(let* ((bootstrap-file
        (expand-file-name "straight/repos/straight.el/bootstrap.el"
                          user-emacs-directory))
       (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))


(add-to-list 'straight-built-in-pseudo-packages 'org)

(straight-use-package 'use-package)
(setq straight-use-package-by-default t
      use-package-always-ensure nil)

;; 🔑 Install critical packages EARLY so local code can require them
;;(straight-use-package 'org)
(straight-use-package 'lsp-mode)
(straight-use-package 'lsp-java)

;; Now local elisp can safely require org/lsp-related stuff
(add-to-list 'load-path "~/.emacs.d/elisp")
(require 'ob-markdown)
(require 'java-lsp)


;; Theme
(load-theme 'modus-vivendi t)        ;; or wombat, tango-dark, ...

;; ---------------------------------------------------------------------------
;; gpt5 splash screen / my-home
;; ---------------------------------------------------------------------------
(require 'my-home)

(setq inhibit-startup-screen t)
(setq initial-buffer-choice #'my-home-buffer)

(global-set-key (kbd "C-c h")
                (lambda ()
                  (interactive)
                  (switch-to-buffer (my-home-buffer))))
;; ---------------------------------------------------------------------------

(setq elpy-shell-starting-directory 'current-directory) ;; default is 'project-root

;; ---------------------------------------------------------------------------
;; Core packages via use-package / straight
;; ---------------------------------------------------------------------------

(use-package htmlize
  :straight t      ;; or :ensure t if you use package.el
  :defer nil)      ;; load eagerly so exporters find it


(use-package tex
  :straight auctex)

(use-package consult
  :defer t)

(use-package affe
  :after consult
  :config
  ;; Manual preview key for `affe-grep'
  (consult-customize affe-grep :preview-key "M-."))

(use-package elpy
  :init
  (elpy-enable))

(use-package conda
  :config
  ;; interactive shell support
  (conda-env-initialize-interactive-shells)
  ;; eshell support
  (conda-env-initialize-eshell)
  ;; auto-activation
  (conda-env-autoactivate-mode t)
  ;; automatically activate a conda env on opening a file
  (add-hook 'find-file-hook
            (lambda ()
              (when (bound-and-true-p conda-project-env-path)
                (conda-env-activate-for-buffer)))))

(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :config
  (exec-path-from-shell-initialize))

;; some tools expect this env var on macOS
(setenv "EMACS" "/Applications/Emacs.app/Contents/MacOS/Emacs")

(use-package zmq
  :straight '(zmq :host github :repo "nnicandro/emacs-zmq")
  :demand t)

(use-package jupyter
  :commands (jupyter-run-server-repl
             jupyter-run-repl
             jupyter-server-list-kernels)

  :straight t
  :after zmq
  :init
  (eval-after-load 'jupyter-org-extensions
    '(unbind-key "C-c h" jupyter-org-interaction-mode-map)))


(use-package sqlite3
  :straight (:host github :repo "pekingduck/emacs-sqlite3-api"))

(use-package anki-editor  
  :straight (:host github :repo "anki-editor/anki-editor"))

(use-package ankiorg
  :straight (:host github :repo "orgtre/ankiorg")
  :custom
  (ankiorg-sql-database
   "~/Library/Application Support/Anki2/j/collection.anki2")
  (ankiorg-media-directory
   "~/Library/Application Support/Anki2/j/collection.media/"))

;; Other packages you had in package-selected-packages; keep them available
(use-package magit      :defer t)
(use-package lsp-mode   :defer t)
(use-package lsp-java   :after lsp-mode :defer t)


;; ---------------------------------------------------------------------------
;; Custom variables / faces (left as-is from Custom)
;; ---------------------------------------------------------------------------
(custom-set-variables
 '(org-agenda-files
   '("/Users/aayushbajaj/Documents/new-site/static/doc/org/tasks.org"))
 '(org-export-with-drawers nil)
 '(org-format-latex-options
   '(:foreground default :background "Transparent" :scale 2.0
                 :html-foreground "Black" :html-background "Transparent"
                 :html-scale 1.0
                 :matchers ("begin" "$1" "$" "$$" "\\(" "\\[")))
 '(org-latex-classes
   '(("standalone" "\\documentclass{standalone}"
      ("\\section{%s}" . "\\section*{%s}")
      ("\\subsection{%s}" . "\\subsection*{%s}")
      ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
      ("\\paragraph{%s}" . "\\paragraph*{%s}")
      ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))
     ("article" "\\documentclass{standalone}")
     ("report" "\\documentclass[11pt]{report}"
      ("\\part{%s}" . "\\part*{%s}")
      ("\\chapter{%s}" . "\\chapter*{%s}")
      ("\\section{%s}" . "\\section*{%s}")
      ("\\subsection{%s}" . "\\subsection*{%s}")
      ("\\subsubsection{%s}" . "\\subsubsection*{%s}"))
     ("book" "\\documentclass[11pt]{book}"
      ("\\part{%s}" . "\\part*{%s}")
      ("\\chapter{%s}" . "\\chapter*{%s}")
      ("\\section{%s}" . "\\section*{%s}")
      ("\\subsection{%s}" . "\\subsection*{%s}")
      ("\\subsubsection{%s}" . "\\subsubsection*{%s}"))))
 '(org-latex-default-class "standalone")
 '(org-latex-image-default-scale "1")
 '(org-log-into-drawer "PROPERTIES")
 '(safe-local-variable-values
   '((eval setq org-preview-latex-default-process 'imagemagick)))
 '(tex-run-command "tex"))

(custom-set-faces
 '(default ((t (:family "Menlo" :foundry "nil" :slant normal
                        :weight regular :height 180 :width normal)))))

;; ---------------------------------------------------------------------------
;; Org + LaTeX preview / export setup
;; ---------------------------------------------------------------------------

(org-babel-do-load-languages
 'org-babel-load-languages
 '((shell   . t)
   (python  . t)
   (markdown . t)
   (jupyter . t)
   (latex   . t)
   (C       . t)
   (java    . t)))

(setq custom-tab-width 4)
(setq-default python-indent-offset custom-tab-width)

(with-eval-after-load 'ox-latex
  (add-to-list 'org-latex-classes
               '("standalone"
                 "\\documentclass{standalone}"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))))

;; Preview backends ----------------------------------------------------------
(setq ajlua3
      '(ajlua3
        :programs ("lualatex" "inkscape")
        :description "pdf > svg"
        :message "you need to install the programs:lualatex and inkscape."
        :image-input-type "pdf"
        :image-output-type "svg"
        :latex-compiler
        ("echo \"O is %O\n o is %o\n f is %f\n F is %F\" >> /Users/aayushbajaj/Documents/site/content/projects/dl/perceptron/debug.tex")
        :image-compiler
        ("echo bullshit bro >> /Users/aayushbajaj/Documents/site/content/projects/dl/perceptron/debug.tex")))

(add-to-list 'org-preview-latex-process-alist ajlua3)

(setq ajlua2
      '(ajlua2
        :programs ("lualatex" "inkscape")
        :description "pdf > svg"
        :message "you need to install the programs:lualatex and inkscape."
        :image-input-type "pdf"
        :image-output-type "svg"

        ;; scale factor: (BUFFER . HTML)
        :image-size-adjust (1.7 . 1.7)

        :post-clean ("")
        :latex-compiler
        ("lualatex -interaction=nonstopmode --shell-escape --output-directory=%o %F")
        :image-converter
        ("inkscape --pdf-poppler --export-text-to-path --export-plain-svg --export-area-drawing --export-filename=out.svg %f"
         "echo image converter was run >> /Users/aayushbajaj/Documents/site/content/projects/dl/perceptron/debug.tex"
         "inkscape --pdf-poppler --export-text-to-path --export-plain-svg --export-area-drawing --export-filename=%O %f")
        :transparent-image-converter
        ("inkscape --pdf-poppler --export-text-to-path --export-plain-svg --export-area-drawing --export-filename=%O %f")))

(add-to-list 'org-preview-latex-process-alist ajlua2)
(setq org-preview-latex-default-process 'ajlua2)

(setq ajlua1
      '(ajlua1
        :programs ("lualatex" "inkscape")
        :description "pdf > svg"
        :message "you need to install the programs:lualatex and inkscape."
        :image-input-type "pdf"
        :image-output-type "svg"
        :latex-compiler
        ("lualatex --interaction=nonstopmode --shell-escape --output-directory=%o %F")
        :image-converter
        ("inkscape --pdf-poppler --export-text-to-path --export-plain-svg --export-area-drawing --export-filename=out.svg %f")))

(add-to-list 'org-preview-latex-process-alist ajlua1)

(setq luamagick
      '(luamagick
        :programs ("lualatex" "magick")
        :description "pdf > png"
        :message "you need to install lualatex and imagemagick."
        :use-xcolor t
        :image-input-type "pdf"
        :image-output-type "png"
        :image-size-adjust (1.0 . 1.0)
        :latex-compiler
        ("lualatex -interaction nonstopmode -output-directory %o %f")
        :image-converter
        ("convert -density %D -trim -antialias %f -quality 100 %O")))

(add-to-list 'org-preview-latex-process-alist luamagick)

(setq org-preview-latex-image-directory ".")
(setq org-startup-with-inline-images t)


(setq org-latex-pdf-process
      '("lualatex -shell-escape -interaction nonstopmode %f"
        "lualatex -shell-escape -interaction nonstopmode %f"))

;; auto adding tex packages
(add-to-list 'org-latex-packages-alist '("" "tikz" t))
(add-to-list 'org-latex-packages-alist '("" "pgfplots" t))
(add-to-list 'org-latex-packages-alist '("" "luacode" t))
(add-to-list 'org-latex-packages-alist '("" "xcolor" t))

;; auctex options
(setq org-latex-compiler "lualatex")
(setq TeX-engine "luatex")

(add-to-list 'org-src-lang-modes '("jupyter-python" . python))

;; Never use hard tabs in Python
(add-hook 'python-mode-hook
          (lambda ()
            (setq indent-tabs-mode nil)))

;; And when editing src blocks in Org
(add-hook 'org-src-mode-hook
          (lambda ()
            (setq indent-tabs-mode nil)))

;; controversial:
(setq-default indent-tabs-mode nil)

;; Org core settings ---------------------------------------------------------
(use-package org
  :straight nil
  :config
  (setq org-M-RET-may-split-line '((default . nil)))
  (setq org-insert-heading-respect-content t)
  (setq org-log-done 'time)
  (setq org-log-into-drawer t)

  (setq org-directory "/Users/aayushbajaj/Documents/new-site/static/doc/org/")
  (setq org-agenda-files (list org-directory))

  (setq org-todo-keywords
        '((sequence "TODO(t)" "WAIT(w!)" "|" "CANCEL(c!)" "DONE(d!)"))))


;; Additional TeX command for AUCTeX ----------------------------------------
(eval-after-load "tex"
  '(add-to-list 'TeX-command-list
                '("LuaLaTeXmk" "latexmk -pdf -pdflatex=\"lualatex %O %S\" %t"
                  TeX-run-TeX nil t)))
(setq TeX-command-default "LuaLaTeXmk")

;; PATH tweaks ---------------------------------------------------------------
(add-to-list 'exec-path "/opt/homebrew/bin/")
(setenv "PATH" (concat "/opt/homebrew/bin:" (getenv "PATH")))

(add-to-list 'exec-path "/opt/anaconda3/bin")
(setenv "PATH" (concat "/opt/anaconda3/bin:" (getenv "PATH")))

(setq org-babel-python-command "/opt/anaconda3/bin/python")

;; bindings ------------------------------------------------------------------
(global-set-key (kbd "C-x t h")
  (lambda ()
    (interactive)
    (tab-bar-new-tab)
    (switch-to-buffer (my-home-buffer))))

;;; --- Org: keep CLOSED/notes inside :PROPERTIES:, no LOGBOOK/planning -----
(require 'org)

;; Optional TODO sequence
(setq org-todo-keywords '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d)" "CANCELLED(c)")))

;;; --- Org: keep CLOSED/notes inside :PROPERTIES:, no LOGBOOK/planning -----

(with-eval-after-load 'org

  (require 'org-tempo)
  
  (setq org-babel-default-header-args:jupyter-python
        '((:session . "leet")))
  ;; <sj TAB => jupyter-python block
  (add-to-list 'org-structure-template-alist
               '("sj" . "src jupyter-python"))
  ;; <sp TAB => python block
  (add-to-list 'org-structure-template-alist
               '("sp" . "src python"))
  
  ;; Global defaults: stop Org from emitting planning/LOGBOOK logs on its own
  (setq org-log-done nil
        org-log-into-drawer nil
        org-log-redeadline nil
        org-log-reschedule nil
        org-log-repeat nil)

  ;; Reassert as buffer-local in every org buffer
  (add-hook 'org-mode-hook
            (lambda ()
              (setq-local org-log-done nil
                          org-log-into-drawer nil
                          org-log-redeadline nil
                          org-log-reschedule nil
                          org-log-repeat nil)))

  ;; Debug toggle
  (defvar my/org-debug nil)

  (defun my/org--dbg (fmt &rest args)
    (when my/org-debug
      (apply #'message (concat "[my/org] " fmt) args)))

  ;; Utilities
  (defun my/org--ts ()
    "Timestamp like [YYYY-MM-DD Day HH:MM]."
    (format-time-string "[%Y-%m-%d %a %H:%M]"))

  (defvar my/org-note-key "note"
    "Property key used for free-form notes inside :PROPERTIES:.")

  (defun my/org--ensure-prop-bounds ()
    "Return (BEG . END) of this heading's :PROPERTIES: block; create if missing."
    (save-excursion
      (org-back-to-heading t)
      (let ((pb (org-get-property-block nil t)))
        (unless pb
          ;; Insert after any planning lines
          (forward-line 1)
          (while (looking-at "^[ \t]*\\(CLOSED:\\|SCHEDULED:\\|DEADLINE:\\|CLOCK:\\)")
            (forward-line 1))
          (insert ":PROPERTIES:\n:END:\n")
          (setq pb (org-get-property-block nil t)))
        pb)))

  ;; PATCH: write KEY lines manually inside :PROPERTIES: (handles CLOSED)
  (defun my/org--prop-upsert-line (key value)
    "Upsert a \":KEY: VALUE\" line inside the current heading's :PROPERTIES: drawer."
    (save-excursion
      (pcase-let* ((`(,beg . ,end) (my/org--ensure-prop-bounds)))
        (let* ((case-fold-search t)
               (re (concat "^[ \t]*:" (regexp-quote key) ":[ \t]*.*$"))
               (indent (save-excursion (goto-char beg) (current-indentation)))
               (newline (format "%s:%s: %s\n" (make-string indent ?\s) key value)))
          (goto-char beg)
          (if (re-search-forward re end t)
              ;; Replace existing line
              (replace-match (string-trim-right newline) t t)
            ;; Insert just before :END:
            (goto-char end)
            (insert newline))))))

  (defun my/org--prop-set (key value)
    "Set/replace KEY line to VALUE in :PROPERTIES: (incl. CLOSED)."
    (my/org--prop-upsert-line key value))

  (defun my/org--prop-append (key value)
    "Append a KEY: VALUE line just before :END: in the drawer."
    (save-excursion
      (pcase-let ((`(,beg . ,end) (my/org--ensure-prop-bounds)))
        (goto-char end) ; beginning of :END:
        (let ((indent (save-excursion (goto-char beg) (current-indentation))))
          (insert (format "%s:%s: %s\n"
                          (make-string indent ?\s) key value))
          (my/org--dbg "Append %s: %s" key value)))))

  (defun my/org--delete-planning-closed-lines ()
    "Remove any planning CLOSED: lines under this heading."
    (save-excursion
      (org-back-to-heading t)
      (let ((end (save-excursion (org-end-of-subtree t t))))
        (forward-line 1)
        (while (re-search-forward "^[ \t]*CLOSED: \\[.+?\\][ \t]*$" end t)
          (my/org--dbg "Deleted stray planning CLOSED at %d" (line-beginning-position))
          (replace-match "" nil nil)
          (when (looking-at "^[ \t]*$")
            (delete-region (point) (line-end-position)))))))

  ;; Suppress Org's own logging while `org-todo` runs
  (defun my/org--around-org-todo-no-log (orig-fn &rest args)
    (let ((org-log-done nil)
          (org-log-into-drawer nil)
          (org-log-redeadline nil)
          (org-log-reschedule nil)
          (org-log-repeat nil)
          (org-todo-log-states nil))
      (apply orig-fn args)))
  (advice-remove 'org-todo #'my/org--around-org-todo-no-log)
  (advice-add    'org-todo :around #'my/org--around-org-todo-no-log)

  ;; After-state-change hook: write CLOSED + note inside drawer, then cleanup
  (defun my/org-after-todo-state-change ()
    ;; Be robust: fire for ANY done-state, not just exact "DONE"
    (when (and (stringp org-state)
               (member org-state org-done-keywords))
      (let* ((ts  (my/org--ts))
             (old (or org-last-state "TODO")))
        (my/org--dbg "Hook fired: %s <- %s" org-state old)
        ;; 1) CLOSED inside :PROPERTIES:
        (my/org--prop-set "CLOSED" ts)
        ;; 2) One-line state-change note inside :PROPERTIES:
        (my/org--prop-append my/org-note-key
                             (format "- State \"%s\" from \"%s\" %s"
                                     org-state old ts))
        ;; 3) Remove any planning CLOSED lines
        (my/org--delete-planning-closed-lines))))
  (remove-hook 'org-after-todo-state-change-hook #'my/org-after-todo-state-change)
  (add-hook    'org-after-todo-state-change-hook #'my/org-after-todo-state-change)

  ;; Manual quick-note: C-c C-z to append a two-line note inside drawer
  (defun my/org-add-note-as-property ()
    "Prompt for a one-line note and store it inside :PROPERTIES: as :note: lines."
    (interactive)
    (let ((txt (read-string "Note: "))
          (ts  (my/org--ts)))
      (my/org--prop-append my/org-note-key (format "- Note taken on %s \\\\" ts))
      (my/org--prop-append my/org-note-key txt)))
  (define-key org-mode-map (kbd "C-c C-z") #'my/org-add-note-as-property)

  ;; Re-assert the local overrides for any already-open Org buffers.
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (derived-mode-p 'org-mode)
        (setq-local org-log-done nil
                    org-log-into-drawer nil
                    org-log-redeadline nil
                    org-log-reschedule nil
                    org-log-repeat nil)))))

(with-eval-after-load 'org-element
  ;; Org < 9.7 doesn't have `org-element--property`, but some packages
  ;; compiled against new Org call it directly. Provide a shim.
  (unless (fboundp 'org-element--property)
    (defun org-element--property (property node &optional dflt _force-undefer)
      "Compatibility shim for packages expecting Org 9.7's AST API.
Return DFLT when PROPERTY is not present."
      (or (org-element-property property node) dflt))))



(defun my/ensure-anki-editor-mode (note)
  "Ensure `anki-editor-mode' is enabled before pushing notes."
  (unless anki-editor-mode
    (anki-editor-mode 1)))
(advice-add #'anki-editor--push-note :before #'my/ensure-anki-editor-mode)

(require 'ansi-color)
(require 'ob-core)  ;; for org-babel-where-is-src-block-result / org-babel-result-end

(defun aj/org-babel-strip-ansi-from-result ()
  "Strip ANSI colour escape codes from the last Org Babel result.

Only does anything when `anki-editor-mode' is enabled in the current buffer."
  (when (and (derived-mode-p 'org-mode)
             (bound-and-true-p anki-editor-mode))
    (let ((beg (org-babel-where-is-src-block-result nil nil)))
      (when beg
        (save-excursion
          (goto-char beg)
          ;; Skip the `#+RESULTS:' line
          (forward-line 1)
          (let ((content-beg (point))
                (content-end (org-babel-result-end)))
            (ansi-color-filter-region content-beg content-end)))))))

(add-hook 'org-babel-after-execute-hook #'aj/org-babel-strip-ansi-from-result)


;; patches anki-editor images:
(require 'cl-lib)

(with-eval-after-load 'anki-editor
  ;; If we had an older version of this advice, remove it first to avoid stacking.
  (ignore-errors
    (advice-remove 'org-html-link #'anki-editor--ox-html-link))

  (defun anki-editor--ox-html-link (oldfun link desc info)
    "Export Org file links as Anki media (images & audio) when :anki-editor-mode is set."
    (let* ((type     (org-element-property :type link))
           (raw-path (org-element-property :path link)))
      (if (and (plist-get info :anki-editor-mode)
               (string= type "file"))
          (let* ((abs-path (expand-file-name
                            raw-path
                            (or (and (buffer-file-name)
                                     (file-name-directory (buffer-file-name)))
                                default-directory)))
                 (stored   (anki-editor-api--store-media-file abs-path)))
            (cond
             ;; Audio file → [sound:...] syntax
             ((cl-some (lambda (ext)
                         (string-suffix-p ext stored t))
                       anki-editor--audio-extensions)
              (format "[sound:%s]" stored))

             ;; Inline image → <img src="...">
             ((org-export-inline-image-p
               link (plist-get info :html-inline-image-rules))
              (format "<img src=\"%s\" alt=\"%s\" />"
                      stored
                      (file-name-sans-extension
                       (file-name-nondirectory raw-path))))

             ;; Other file links → fall back to default HTML behavior
             (t
              (funcall oldfun link desc info))))
        ;; Non-file links → just use Org's default HTML exporter
        (funcall oldfun link desc info))))

  (advice-add 'org-html-link :around #'anki-editor--ox-html-link))

(with-eval-after-load 'ox-html
  (defun aj/org-html-src-block-to-pre-code (text backend info)
    "Wrap HTML src blocks in <pre><code> for highlight.js / Anki.

TEXT is the HTML for a single src-block."
    (if (and (org-export-derived-backend-p backend 'html)
             (string-match "\\`<pre class=\"src src-\\([^\"\n]+\\)\">" text))
        (let* ((lang (match-string 1 text))
               (body-start (match-end 0))
               (body-end   (string-match "</pre>\\'" text))
               (body       (substring text body-start body-end)))
          (format "<pre><code class=\"language-%s\">%s</code></pre>"
                  lang body))
      text))

  (add-to-list 'org-export-filter-src-block-functions
               #'aj/org-html-src-block-to-pre-code))


;;; allow duplicates on people + artworks decks:
(with-eval-after-load 'anki-editor
  (defun aj/anki-editor-api--note-allow-dups-for-selected-decks (orig note)
    "Wrap `anki-editor-api--note' to allow duplicates in specific decks."
    (let* ((res  (funcall orig note))
           (deck (anki-editor-note-deck note)))
      (when (and deck
                 (member deck '("Default::people"
                                "Default::artworks")))
        (let ((options (plist-get res :options)))
          ;; Force :allowDuplicate t for these decks only
          (setq options (plist-put options :allowDuplicate t))
          (plist-put res :options options)))
      res))

  (advice-add 'anki-editor-api--note :around
              #'aj/anki-editor-api--note-allow-dups-for-selected-decks))

(with-eval-after-load 'anki-editor
  ;; Core helper: operate on the *current note* (the heading with ANKI properties)
  (defun aj/anki--prepend-heading-into-this-cloze-text ()
    "For the current note, prepend heading into the Text field
if this is a Cloze note with :ANKI_PREPEND_HEADING: t."
    (save-excursion
      (save-restriction
        (widen)
        ;; Make sure we are at the note's main heading (** 200, Number of Islands ...)
        (org-back-to-heading t)
        (let* ((note-type (org-entry-get nil "ANKI_NOTE_TYPE" t))
               (prepend   (org-entry-get nil "ANKI_PREPEND_HEADING" t)))
          (when (and note-type prepend
                     (string-match-p "cloze" (downcase note-type))
                     (string= (downcase prepend) "t"))
            (let* ((heading    (org-get-heading t t t t)) ; "200, Number of Islands"
                   (note-level (org-outline-level))
                   (text-level (1+ note-level))
                   (text-stars (make-string text-level ?*))
                   (text-re    (concat "^" text-stars " Text\\b")))
              (org-narrow-to-subtree)
              (goto-char (point-min))
              (when (re-search-forward text-re nil t)
                ;; Now at the *** Text headline
                (forward-line 1)
                (let ((subtree-end (save-excursion (org-end-of-subtree t t))))
                  ;; skip blank lines after *** Text
                  (while (and (< (point) subtree-end)
                              (looking-at "^[ \t]*$"))
                    (forward-line 1))
                  (if (>= (point) subtree-end)
                      ;; Empty Text subtree: just insert heading
                      (insert heading "\n\n")
                    (let* ((ls   (line-beginning-position))
                           (le   (line-end-position))
                           (line (buffer-substring-no-properties ls le)))
                      (cond
                       ;; already has heading
                       ((string= line heading) nil)
                       ;; literal 'Text' placeholder → replace it
                       ((string-match-p "^Text[ \t]*$" line)
                        (delete-region ls (min (1+ le) subtree-end))
                        (insert heading "\n\n"))
                       ;; otherwise, insert heading above current first content line
                       (t
                        (beginning-of-line)
                        (insert heading "\n\n"))))))
              (widen)))))))

  ;; Public command: current note vs whole file
  (defun aj/anki-prepend-heading-into-cloze-text (&optional scope)
    "Prepend headings into Cloze Text fields.

Without prefix arg, operate only on the current note.
With prefix arg (C-u), process all notes in the file that have
ANKI_NOTE_TYPE=\"Cloze\" and ANKI_PREPEND_HEADING=\"t\"."
    (interactive "P")
    (if scope
        ;; whole file
        (org-map-entries
         #'aj/anki--prepend-heading-into-this-cloze-text
         "+ANKI_NOTE_TYPE=\"Cloze\"+ANKI_PREPEND_HEADING=\"t\""
         'file)
      ;; just current note
      (aj/anki--prepend-heading-into-this-cloze-text)))

  ;; Wrap push commands so they always run the fixer first
  (defun aj/anki-push-notes-with-heading (&optional arg)
    "Prepend headings into Cloze Text fields, then push notes."
    (interactive "P")
    (aj/anki-prepend-heading-into-cloze-text t) ; whole file
    (let ((current-prefix-arg arg))
      (call-interactively #'anki-editor-push-notes)))

  (defun aj/anki-push-note-at-point-with-heading (&optional arg)
    "Prepend heading into this Cloze note's Text field, then push it."
    (interactive "P")
    (aj/anki-prepend-heading-into-cloze-text nil) ; current note
    (let ((current-prefix-arg arg))
      (call-interactively #'anki-editor-push-note-at-point))))

;; anki-editor keybinds:
(with-eval-after-load 'org
  ;; anki-editor keybindings under "C-c a ..."
  (define-key org-mode-map (kbd "C-c a i") #'anki-editor-insert-note)
  (define-key org-mode-map (kbd "C-c a p") #'aj/anki-push-note-at-point-with-heading)
  (define-key org-mode-map (kbd "C-c a P") #'aj/anki-push-notes-with-heading)
  (define-key org-mode-map (kbd "C-c a s") #'anki-editor-sync-collection)
  (define-key org-mode-map (kbd "C-c a m") #'anki-editor-mode)
  (define-key org-mode-map (kbd "C-c a d") #'anki-editor-set-deck)
  (define-key org-mode-map (kbd "C-c a h") #'anki-editor-toggle-prepend-heading)
  (define-key org-mode-map (kbd "C-c a c") #'anki-editor-cloze-region))


;;; init.el ends here


