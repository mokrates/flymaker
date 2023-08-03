; -*- lexical-binding: t ; -*-

(require 'flymaker)

(flymaker "pycodestyle" "pycodestyle" ("pycodestyle" "-")
	  "^[^:]+:\\(?1:[0-9]+\\):\\(?2:[0-9]+\\):\\(?3:.*\\)$"
	  :typeform :warning
	  :lang-mode-hook python-mode-hook)

(flymaker "pyflakes3" "pyflakes3" ("pyflakes3")
	  "^[^:]+:\\(?1:[0-9]+\\):\\(?2:[0-9]+\\):\\(?3:.*\\)$"
	  :typeform :error
	  :lang-mode-hook python-mode-hook)
