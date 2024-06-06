#lang racket
;
; Example of how to use an SSL client certificate with Racket:
;
; Connecting to host.docker.internal on port 8443
; Request path: /
; Starting SSL handshake...
; SSL handshake successful
; Connected to host.docker.internal on port 8443
; Sending request:
; GET / HTTP/1.1
; Host: host.docker.internal
; Connection: close
;
; Request sent, awaiting response...
; HTTP/1.1 200 OK
; Date: Thu, 06 Jun 2024 10:39:24 GMT
; Content-Length: 2
; Content-Type: text/plain; charset=utf-8
; Connection: close
;
; OK
;
; Response received, closing connection...
;

(require openssl
         openssl/mzssl
         net/url
         racket/port)

(define client-cert "client.crt")
(define client-key "client.key")

(define ctx (ssl-make-client-context
              #:private-key (list 'pem client-key)
              #:certificate-chain client-cert))

(ssl-set-verify! ctx #t) ; verify the connection
(ssl-load-verify-root-certificates! ctx "ca.pem")

(define (print-response in)
  (define headers (port->lines in))
  (for ([line headers])
    (printf "~a\n" line))
  (newline))

(define (path->string path-list)
  (if (empty? path-list)
    "/"
    (string-append "/" (string-join (map path/param-path path-list) "/"))))

(define (query->string query-list)
  (if (empty? query-list)
    ""
    (string-append "?" (string-join (map (λ (param) (format "~a=~a" (symbol->string (car param)) (cdr param))) query-list) "&"))))

(define (connect-to-server url)
  (define parsed-url (string->url url))
  (define host (url-host parsed-url))
  (define port (url-port parsed-url))
  (define path (path->string (url-path parsed-url)))
  (define query (query->string (url-query parsed-url)))
  (define full-path (string-append path query))
  (printf "Connecting to ~a on port ~a\n" host (or port 443))
  (printf "Request path: ~a\n" full-path)
    (printf "Starting SSL handshake...\n")
    (define-values (in out) (ssl-connect host (or port 443) ctx))
    (printf "SSL handshake successful\n")
    (printf "Connected to ~a on port ~a\n" host (or port 443))
    (printf "Sending request:\nGET ~a HTTP/1.1\r\nHost: ~a\r\nConnection: close\r\n\r\n" full-path host)
    (fprintf out "GET ~a HTTP/1.1\r\n" full-path)
    (fprintf out "Host: ~a\r\n" host)
    (fprintf out "Connection: close\r\n")
    (fprintf out "\r\n")
    (flush-output out)
    (printf "Request sent, awaiting response...\n")
    (print-response in)
    (printf "Response received, closing connection...\n")
    (close-input-port in)
    (close-output-port out)
  )

(define url "https://host.docker.internal:8443/")
(connect-to-server url)
