(in-package :sandbox)

(defmacro etouq (form)
  (eval form))

(fuktard:eval-always
 (progn
   (defun preach (value form)
     (mapcar (lambda (x)
	       (list value x))
	     form))

   (defun raps (times form)
     (make-list times :initial-element form))

   (defun ngorp (&rest forms)
     (cons (quote progn)
	   (apply (function nconc) forms)))
   (defun ensure (place otherwise)
     (let ((value-var (gensym))
	   (exists-var (gensym)))
       `(or ,place
	    (multiple-value-bind (,value-var ,exists-var) ,otherwise
	      (if ,exists-var
		  (values (setf ,place ,value-var) ,exists-var))))))))

(defparameter *something* #.(or *compile-file-truename* *load-truename*))

(defparameter ourdir
  (make-pathname :host (pathname-host *something*)
		 :directory (pathname-directory *something*)))


(defconstant +single-float-pi+ (coerce pi 'single-float))
(defconstant +single-float-two-pi+ (coerce (* 2 pi) 'single-float))
(defconstant +single-float-half-pi+ (coerce (/ pi 2) 'single-float))

(defun clamp (x min max)
  (max (min x max) min))

(defparameter *temp-matrix* (cg-matrix:identity-matrix))
(defparameter *temp-matrix2* (cg-matrix:identity-matrix))
(defparameter *temp-matrix3* (cg-matrix:identity-matrix))
(defparameter *x-unit* (cg-matrix:vec 1.0 0.0 0.0))

(defun byte-read (path)
   (with-open-file (stream path :element-type '(unsigned-byte 8))
     (let* ((len (file-length stream))
	    (data (make-array len :element-type '(unsigned-byte 8))))
       (dotimes (n len)
	 (setf (aref data n) (read-byte stream)))
       data)))

(defun file-string (path)
  (with-open-file (stream path)
    (let ((data (make-string (file-length stream))))
      (read-sequence data stream)
      data)))

(defun spill-hash (hash)
  (loop for key being the hash-keys of hash
     using (hash-value value)
     do (format t "~S ~S~%" key value)))

(defun print-bits (n)
  (format t "~64,'0b" n))

(defun getapixel (h w image)
  (destructuring-bind (height width c) (array-dimensions image)
    (declare (ignore height))
    (make-array 4 :element-type (array-element-type image)
		:displaced-to image
		:displaced-index-offset (* c (+ w (* h width))))))

;;;;load a png image from a path
(defun load-png (filename)
  (opticl:read-png-file filename))

(defun fmakunbounds (symbol-list)
  (dolist (symbol symbol-list)
    (fmakunbound symbol)))

(defun makunbounds (symbol-list)
  (dolist (symbol symbol-list)
    (makunbound symbol)))

(defmacro xfmakunbounds (&body symbols)
  `(fmakunbounds (quote ,symbols)))

(defmacro xmakunbounds (&body symbols)
  `(makunbounds (quote ,symbols)))

(defun complex-modulus (c)
  (sqrt (realpart (* c (conjugate c)))))

(defparameter foo
  (let ((a (write-to-string "Hello World")))
    (map-into a
	      (lambda (x) (char-downcase x)) a)))

;;;;flip an image in-place - three dimensions - does not conse
(defun flip-image (image)
  (let ((dims (array-dimensions image)))
    (let ((height (pop dims))
	  (width (pop dims)))
      (if dims
	  (let ((components (car dims)))
	    (dobox ((h 0 (- height (ash height -1)))
		    (w 0 width)
		    (c 0 components))
		   (rotatef (aref image (- height h 1) w c)
			    (aref image h w c))))
	  (dobox ((h 0 (- height (ash height -1)))
		  (w 0 width))
	      (rotatef (aref image (- height h 1) w)
		       (aref image h w))))))
  image)


(defparameter dir-resource (merge-pathnames #P"res/" ourdir))
(defparameter dir-shader (merge-pathnames #P"shaders/" dir-resource))

(defun shader-path (name)
  (merge-pathnames name dir-shader))

(defun img-path (name)
  (merge-pathnames name dir-resource))

(defun name-mesh (display-list-name mesh-func)
  (setf (gethash display-list-name *g/call-list-backup*)
	(lambda ()
	  (create-call-list-from-func mesh-func))))

(defun texture-imagery (texture-name image-name)
  (setf (gethash texture-name *g/texture-backup*)
	(lambda ()
	  (pic-texture (get-image image-name)))))

(defun name-shader (shader-name vs fs attributes)
  (setf (gethash shader-name *g/shader-backup*)
	(lambda ()
	  (make-shader-program-from-strings
	   (get-text vs) (get-text fs) attributes))))

(defun src-image (name src-path)
  (setf (gethash name *g/image-backup*)
	(lambda ()
	  (let ((img (load-png src-path)))
	    (flip-image img)
	    img))))

(defun src-text (name src-path)
  (setf (gethash name *g/text-backup*)
	(lambda ()
	  (file-string src-path))))

(progn
  (defparameter *g/image* (make-hash-table :test 'eq))		    ;;raw image arrays
  (defun get-image (name)
    (etouq
     (ensure (quote (gethash name *g/image*))
	     (quote (let ((image-func (gethash name *g/image-backup*)))
		      (when (functionp image-func)
			(values (funcall image-func) t))))))))
(defparameter *g/image-backup* (make-hash-table :test 'equal))

(progn
  (defparameter *g/text* (make-hash-table :test 'eq))   ;;text: sequences of bytes
  (defun get-text (name)
    (etouq
     (ensure (quote (gethash name *g/text*))
	     (quote (let ((text-func (gethash name *g/text-backup*)))
		      (when (functionp text-func)
			(values (funcall text-func) t))))))))
(defparameter *g/text-backup* (make-hash-table :test 'eq))

(progn
  (defparameter *g/call-list* (make-hash-table :test 'eq));;opengl call lists
  (defun get-display-list (name)
    (etouq
     (ensure (quote (gethash name *g/call-list*))
	     (quote (let ((display-list-func (gethash name *g/call-list-backup*)))
		      (when (functionp display-list-func)
			(values (funcall display-list-func) t))))))))
(defparameter *g/call-list-backup* (make-hash-table :test 'eq))

(progn
  (defparameter *g/texture* (make-hash-table :test 'eq)) ;;opengl textures
  (defun get-texture (name)
    (etouq
     (ensure (quote (gethash name *g/texture*))
	     (quote (let ((image-data-func (gethash name *g/texture-backup*)))
		      (when (functionp image-data-func)
			(values (funcall image-data-func) t))))))))
(defparameter *g/texture-backup* (make-hash-table :test 'eq))

(progn
  (defparameter *g/shader* (make-hash-table :test 'eq)) ;;opengl shaders
  (defun get-shader (name)
    (etouq
     (ensure
      (quote (gethash name *g/shader*))
      (quote (let ((shader-make-func (gethash name *g/shader-backup*)))
	       (when (functionp shader-make-func)
		 (values (funcall shader-make-func) t))))))))
(defparameter *g/shader-backup* (make-hash-table :test 'eq))


(defun lcalllist-invalidate (name)
  (let ((old (get-display-list name)))
    (remhash name *g/call-list*)
    (when old (gl:delete-lists old 1))))

(defun create-call-list-from-func (func)
  (let ((the-list (gl:gen-lists 1)))
    (gl:new-list the-list :compile)
    (funcall func)
    (gl:end-list)
    the-list))

