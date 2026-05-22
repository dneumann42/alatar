(import scheme
        chicken.load)

(load-relative "prelude.scm")

(define-class <command> ()
  ((sub-commands initform: '()
		 accessor: command-sub-commands)))

(define-method (print-object (self <command>) port)
  (display "#<command " port)
  (display (command-name self) port)
  (display ">" port))

(define-method (command-name (self <command>))
  (error "Command must extend name"))
(define-method (execute (self <command>) args) #f)

(define packages-path
  (string-append (or (get-environment-variable "ALATAR_HOME")
		     (string-append (get-environment-variable "HOME")
				    "/.alatar"))
		 "/packages"))

(define-class <package-command> (<command>))
(define-method (command-name (self <package-command>)) 'pkg)
(define-method (execute (self <package-command>) args)
  (define (read-all-sexp port)
    (let loop ((xs '()))
      (let ((x (read port)))
	(if (eof-object? x)
	    (reverse xs)
	    (loop (cons x xs))))))
  (define system-packages '())
  (define flatpak-packages '())
  (define (package->string pkg)
    (if (symbol? pkg) (symbol->string pkg) pkg))
  (define (run-command parts)
    (system* (join-strings (map qs parts) " ")))
  (define (install-system-packages packages)
    (unless (null? packages)
      (run-command (append '("sudo" "pacman" "-S" "--needed")
			   (map package->string packages)))))
  (define (install-flatpak-packages packages)
    (unless (null? packages)
      (run-command (append '("flatpak" "install" "-y" "flathub")
			   (map package->string packages)))))
  (define (organize-package pkg)
    (match pkg
      ((? symbol? name)
       (set! system-packages (cons name system-packages)))
      (('flatpak (? symbol? name))
       (set! flatpak-packages (cons name flatpak-packages)))
      (else
       (error "Invalid package syntax" pkg))))
  (let ((packages (call-with-input-file packages-path read-all-sexp)))
    (for-each organize-package packages))
  (set! system-packages (reverse system-packages))
  (set! flatpak-packages (reverse flatpak-packages))
  (install-system-packages system-packages)
  (install-flatpak-packages flatpak-packages)
  (call-next-method))

(define-class <director-command> (<command>))
(define-method (command-name (self <director-command>)) 'dir)
(define-method (execute (self <director-command>) args)
  (display "DIRECTOR")
  (call-next-method))

(define commands
  (list
   (make <package-command>)
   (make <director-command>)))

(define (execute-command name args)
  (let ((maybe-cmd (find
		    (lambda (cmd)
		      (eq? (command-name cmd) name)) commands)))
    (if maybe-cmd
	(execute maybe-cmd args)
	(error "Undefined command"))))

(execute-command 'pkg (list 'install))
