;;; flymaker.el --- A generalized Flymake backend  -*- lexical-binding: t; -*-

(cl-defmacro flymaker (fm-name executable command fm-regex &key typeform lang-mode-hook)
  "
fm-name: the name of the flymaker, e.g. 'pycodestyle'
executable: name of the executable. used to check if it is available. e.g. \"pycodestyle\"
command: list of command to be executed. command gets source piped in. eg (\"pycodestyle\" \"-\")
fm-regex: has to have 3 matchgroups: 1: line, 2: col, 3: msg. e.g.
  \"^[^:]+:\\(?1:[0-9]+\\):\\(?2:[0-9]+\\):\\(?3:.*\\)$\"
typeform: form to call, returning :warning, :error or :note, default: :error
lang-mode-hook: the hook of the mode which should start this flymaker
"  
  (let ((sym-fm-flymaker--proc
	 (intern (format "%s-flymaker--proc" fm-name)))
	(sym-fm-flymaker
	 (intern (format "%s-flymaker" fm-name)))
	(sym-fm-flymaker-setup-backend
	 (intern (format "%s-flymaker-setup-backend" fm-name)))
	(sym-fm-flymaker-group
	 (intern (format "%s-flymaker-group" fm-name)))

	(sym-fm-flymaker--add-to-mode-hook
	 (intern (format "%s-flymaker--add-to-mode-hook" fm-name)))
	(sym-fm-flymaker--enable-help
	 (intern (format "%s-flymaker--enable-help" fm-name))))
    
    `(progn
       
       (defvar-local ,sym-fm-flymaker--proc nil)
       
       (defun ,sym-fm-flymaker (report-fn &rest _args)
	 (unless (executable-find ,executable)
	   (error ,(format "Cannot find a suitable '%s'" executable)))
	 ;; If a live process launched in an earlier check was found, that
	 ;; process is killed.  When that process's sentinel eventually runs,
	 ;; it will notice its obsoletion, since it have since reset
	 ;; ,sym-fm--flymaker-proc' to a different value

	 (when (process-live-p ,sym-fm-flymaker--proc)
	   (kill-process ,sym-fm-flymaker--proc))

	 ;; Save the current buffer, the narrowing restriction, remove any
	 ;; narrowing restriction.
	 
	 (let ((source (current-buffer)))
	   (save-restriction
	     (widen)
	     ;; Reset the `fm-flymaker--proc' process to a new process
	     ;; calling the mo-py-codestyle tool.
	     ;;
	     (setq
	      ,sym-fm-flymaker--proc
	      (make-process
               :name ,(format "flymaker-%s" fm-name) :noquery t :connection-type 'pipe
               ;; Make output go to a temporary buffer.
               ;;
               :buffer (generate-new-buffer ,(format" *flymaker-%s*" fm-name))
	       :command ',command
	       :sentinel
               (lambda (proc _event)
		 ;; Check that the process has indeed exited, as it might
		 ;; be simply suspended.
		 ;;
		 (when (eq 'exit (process-status proc))
		   (unwind-protect
                       ;; Only proceed if `proc' is the same as
                       ;; `*-flymaker--proc', which indicates that
                       ;; `proc' is not an obsolete process.
                       ;;
                       (if (with-current-buffer source (eq proc ,sym-fm-flymaker--proc))
			   (with-current-buffer (process-buffer proc)
			     (switch-to-buffer (process-buffer proc))
			     (goto-char (point-min))
			     ;; Parse the output buffer for diagnostic's
			     ;; messages and locations, collect them in a list
			     ;; of objects, and call `report-fn'.
			     ;;
			     (cl-loop
			      while (search-forward-regexp ,fm-regex nil t)  ;; line col msg
			      for msg = (match-string 3)
			      for (beg . end) = (flymake-diag-region
						 source
						 (string-to-number (match-string 1))
						 (string-to-number (match-string 2)))
			      ,@(if typeform
				    `(for type = ,typeform)
				  :error)
			      collect (flymake-make-diagnostic source
                                                               beg
                                                               end
                                                               type
                                                               msg)
			      into diags
			      finally (funcall report-fn diags)))
			 (flymake-log :warning "Canceling obsolete check %s"
				      proc))
		     ;; Cleanup the temporary buffer used to hold the
		     ;; check's output.
		     ;;
		     (kill-buffer (process-buffer proc)))))))
	     ;; Send the buffer contents to the process's stdin, followed by
	     ;; an EOF.
	     ;;
	     (process-send-region ,sym-fm-flymaker--proc (point-min) (point-max))
	     (process-send-eof ,sym-fm-flymaker--proc))))

       (defun ,sym-fm-flymaker-setup-backend ()
	 (make-variable-buffer-local 'flymake-diagnostic-functions)
	 (add-hook 'flymake-diagnostic-functions ',sym-fm-flymaker)
	 
	 (when ,sym-fm-flymaker--enable-help
	   (if (listp help-at-pt-display-when-idle)
	       (add-to-list 'help-at-pt-display-when-idle 'flymake-diagnostic)
	     (setf help-at-pt-display-when-idle '(flymake-diagnostic)))
	   (help-at-pt-set-timer)))

       (defgroup ,sym-fm-flymaker-group
	 nil
	 ,(format "%s-flymaker: a generated flymake checker for '%s' by flymaker" fm-name fm-name))
       
       ,(when lang-mode-hook
	  `(defcustom ,sym-fm-flymaker--add-to-mode-hook t
	     ,(format "Add %s-flymaker to %s." fm-name (symbol-name lang-mode-hook))
	     :type 'boolean
	     :group ',sym-fm-flymaker-group
	     :set (lambda (var val)
		    (set-default var val)
		    (cond (val
			   (add-hook ',lang-mode-hook ',sym-fm-flymaker-setup-backend)
			   (add-hook ',lang-mode-hook (lambda () (flymake-mode t))))
			  (:else
			   (remove-hook ',lang-mode-hook ',sym-fm-flymaker-setup-backend))))))
       
       (defcustom ,sym-fm-flymaker--enable-help t
	 ,(format "enable help at point for %s-flymaker" fm-name)
	 :type 'boolean
	 :group ',sym-fm-flymaker-group)
       
       ;; don't know if the :set already does this
       ;; (when ,sym-fm-flymaker--add-to-mode-hook
       ;; 	 (add-hook ',lang-mode-hook ',sym-fm-flymaker-setup-backend)
       ;; 	 (add-hook ',lang-mode-hook (lambda () (flymake-mode t))))
       )))

;;;

(provide 'flymaker)
