#lang racket/base
;; Project-local YAMD plugin for page metadata.
;;
;; Usage:
;;
;;   #use(meta)
;;   #meta(created: "2026 07 12" edited: "2026 07 12" tags: '("kp2pml30"))
;;
;; The site generator reads these rendered HTML meta tags into tree.json, RSS,
;; and sitemap data. The legacy "date" field is emitted as the edited date so
;; older consumers keep working.

(require racket/string
         yamd/runtime)

(provide meta)

(define (meta #:created created #:edited edited #:tags tags)
  (unless (and (list? tags) (andmap string? tags))
    (error 'meta "tags must be a list of strings, got ~e" tags))
  (define tag-content (string-join tags ","))
  (raw 'html
       (string-append
        (meta-html "date-created" created)
        (meta-html "date-edited" edited)
        (meta-html "date" created)
        (meta-html "tags" tag-content))
       #t))

(define (meta-html name content)
  (format "<meta name=\"~a\" content=\"~a\">" (html-attr-escape name) (html-attr-escape content)))

(define (html-attr-escape v)
  (for/fold ([s (format "~a" v)])
            ([replacement (in-list '(("&" . "&amp;")
                                      ("\"" . "&quot;")
                                      ("<" . "&lt;")
                                      (">" . "&gt;")))])
    (string-replace s (car replacement) (cdr replacement))))
