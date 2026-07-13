(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require "helix/editor.scm")
(require "helix/configuration.scm")

(cursorline #t)
(line-number "relative")
(scrolloff 4)

(define (reload-config)
  (helix.config-reload))

(define (git-status)
  (helix.run-shell-command "git status"))

(guard (exn [else (display "oil.hx not installed. To enable filesystem buffer editing, run:\n  forge pkg install --git https://github.com/Ra77a3l3-jar/oil.hx.git\n") #f])
  (require "oil/oil.scm")
  (oil-configure! #t #t)
  (keymap (global)
    (normal
      (space
        (t (e (helix.oil)))))))

(guard (exn [else (display "streal.hx not installed. To enable file bookmarking navigation, run:\n  forge pkg install --git https://github.com/kn66/streal.hx.git\n") #f])
  (require "streal/streal.scm"))

(guard (exn [else (display "steel-pty not installed. To enable in-editor terminal panes, run:\n  forge pkg install --git https://github.com/mattwparas/steel-pty.git\n") #f])
  (require "steel-pty/term.scm"))

(guard (exn [else (display "recentf cog not installed. Run:\n  forge pkg install --git https://github.com/mattwparas/helix-config.git\n") #f])
  (load-package "cogs/recentf.scm"))

(guard (exn [else (display "file-tree cog not installed. Run:\n  forge pkg install --git https://github.com/mattwparas/helix-config.git\n") #f])
  (load-package "cogs/file-tree.scm"))

(guard (exn [else (display "git-status-picker cog not installed. Run:\n  forge pkg install --git https://github.com/mattwparas/helix-config.git\n") #f])
  (load-package "cogs/git-status-picker.scm"))
