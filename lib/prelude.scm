(import scheme
        chicken.base
        chicken.file
        chicken.pathname
        chicken.platform
        chicken.process
        chicken.process-context)

(define (module-available? module-name)
  (let ((import-base (string-append module-name ".import")))
    (let loop ((dirs (repository-path)))
      (and (pair? dirs)
           (or (file-exists? (make-pathname (car dirs) import-base "so"))
               (file-exists? (make-pathname (car dirs) import-base "scm"))
               (loop (cdr dirs)))))))

(define (ensure-egg module-name egg-name)
  (unless (module-available? module-name)
    (print "Installing missing egg: " egg-name)
    (let ((status (system (string-append "chicken-install -s " (qs egg-name)))))
      (unless (zero? status)
        (error "Failed to install egg" egg-name)))))

(ensure-egg "srfi-1" "srfi-1")
(ensure-egg "coops" "coops")
(ensure-egg "matchable" "matchable")

(import srfi-1
        coops
        matchable)

(define (join-strings xs sep)
  (if (null? xs)
      ""
      (let loop ((xs (cdr xs))
                 (acc (car xs)))
        (if (null? xs)
            acc
            (loop (cdr xs) (string-append acc sep (car xs)))))))
