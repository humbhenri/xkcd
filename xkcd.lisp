#!/usr/bin/sbcl --script

;; Download xkcd commics
;; example: sbcl --script xkcd.lisp 1111 .

(load "~/.sbclrc")

(ql:quickload :drakma)
(ql:quickload :yason)

(defun download-json-as-alist (uri)
  (yason:parse 
   (flexi-streams:octets-to-string 
    (drakma:http-request uri)) :object-as :alist))

(defun get-xkcd (&optional number)
  (download-json-as-alist 
     (format nil "http://xkcd.com/~a/info.0.json" (if number number ""))))

(defun download (uri &optional dir)
  (let* ((name (file-namestring uri))
	 (file (ensure-directories-exist 
		(pathname (if dir (format nil "~a/~a" dir name) name))))
	(content (drakma:http-request uri :want-stream t))
	(buf (make-array 4096 :element-type '(unsigned-byte 8) :adjustable t
                          :fill-pointer 4096)))
    (setf (flexi-streams:flexi-stream-external-format content) :utf-8)
    (with-open-file (out file 
			 :direction :output
			 :element-type '(unsigned-byte 8)
			 :if-does-not-exist :create
			 :if-exists :supersede)
      (loop for pos = (read-sequence buf content)
	 while (plusp pos)
	 do (write-sequence buf out :end pos)))))

(defun download-xkcd-image (&key number dir)
  (let ((xkcd (get-xkcd number)))
    (download (cdr (assoc "img" xkcd :test #'string=)) dir)))

;; Main
(let ((args sb-ext:*posix-argv*))
  (destructuring-bind (_ number dir) args
    (download-xkcd-image :number number :dir dir)))
    