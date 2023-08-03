# flymaker #
flymaker is an emacs lisp macro to easily define flymake backends

# how to create flymake backends #
see `flymakers.el`. You HAVE to define lexical binding where you use
the macro

The regex-argument has to create three match-groups, denoted  
`\\(?1:... \\)` to `\\(?3: ... \\)`. You can have more, but not less.
The `?1:`-group has to capture the line, the `?2:`-group has to
capture the column, the `?3:`-group has to capture the message. If
there is no column to capture, leave the `?2:`.

The `:typeform`-argument can be dynamic. There are `(match-string 1)`
to `(match-string 3)` (actually just as many as you define in your
regex) from which you can derive if your message is an :error, a
:warning or a :note

## installation ##

Put the `.el`-files into your `~/.emacs.d`.

in your `~/.emacs` do

	;; this one defines the macro
    (load "~/.emacs.d/flymaker.el")
	
	;; this one, atm, defines a `pycodestyle' and a `pyflakes3' backend
	(load "~/.emacs.d/flymakers.el")
	
