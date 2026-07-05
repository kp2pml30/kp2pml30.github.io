#lang racket/base
;; Project-local YAMD plugin for the Japanese reference pages.
;;
;; Lives in the `jp` collection under frontend/yamd-lib (outside the document
;; tree), put on Racket's search path so the render resolves it as a
;; collection, independent of the document's depth:
;;
;;   PLTCOLLECTS=":<repo>/frontend/yamd-lib" yamd doc.yamd   # generator does this
;;   #use(jp/furigana)                                       # in the .yamd file
;;
;; Two ordinary functions (Content in, IR out — no custom body reader, since
;; both take plain markup bodies):
;;
;;   #furigana{来る}{くる}  ->  <ruby>来る<rt>くる</rt></ruby>
;;       Ruby annotation: base text + its kana reading. Two brace bodies, one
;;       positional argument each (the reader passes one arg per {} body, as
;;       with std/table's #row{a}{b}).
;;
;;   #bordered              ->  adds class="bordered" to every <table> in the
;;       #table(header: 1)      body. std/table emits a plain <table>; the site
;;         ...                  CSS styles table.bordered, so a migrated table
;;                              must be wrapped in #bordered to keep its borders.
;;
;; Both emit only HTML tags; ruby has no markdown/typst mapping, so these pages
;; are HTML-only by design (which matches the site — it renders HTML fragments).

(require yamd/runtime)

(provide furigana bordered)

;; #furigana{base}{reading} — ruby text.
(define (furigana base reading)
  (elem 'ruby base (elem 'rt reading)))

;; #bordered{ …#table… } — tag every <table> in the body with class="bordered".
;; Recurses, so a table nested anywhere in the body is caught; every other node
;; (whitespace, prose, the table's own children) passes through untouched.
(define (bordered . bodies)
  (add-bordered bodies))

(define (add-bordered c)
  (cond
    [(list? c) (map add-bordered c)]
    [(and (element? c) (eq? (element-tag c) 'table))
     (element 'table
              (cons '(class . "bordered") (element-attrs c))
              (element-children c)
              (element-loc c))]
    [else c]))

(module+ test
  (require rackunit)

  ;; furigana: base + reading -> ruby/rt
  (check-equal? (furigana "来る" "くる")
                (elem 'ruby "来る" (elem 'rt "くる")))
  ;; base and reading are arbitrary Content (lists survive)
  (check-equal? (furigana (list "食" "べる") "たべる")
                (elem 'ruby (list "食" "べる") (elem 'rt "たべる")))

  ;; bordered: a table in the body gains the class; prose is untouched
  (check-equal?
   (bordered (list "\n" (elem 'table (elem 'tbody (elem 'tr (elem 'td "x")))) "\n"))
   (list "\n"
         (element 'table '((class . "bordered"))
                  (list (elem 'tbody (elem 'tr (elem 'td "x")))) #f)
         "\n"))
  ;; a table nested deeper is still caught
  (check-equal?
   (add-bordered (list (elem 'div (elem 'table))))
   (list (elem 'div (element 'table '((class . "bordered")) '() #f))))
  ;; no table -> body unchanged
  (check-equal? (bordered (list "just prose")) (list "just prose")))
