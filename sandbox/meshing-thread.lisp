(in-package :sandbox)

(defparameter mesher-thread nil)
(defun designatemeshing ()
  (unless (mesherthreadbusy)
    (if mesher-thread
	(getmeshersfinishedshit))
    (let ((achunk (dirty-pop)))
      (when achunk
	(giveworktomesherthread achunk)))))

(defun shape-list (the-shape len)
  ;; (declare (optimize (speed 3) (safety 0)))
  (unless (zerop len)
    (let ((ourlist (gl:gen-lists 1))
	  (verts the-shape)
	  (vertsize 6))
      (declare (type (simple-array single-float *) verts))
      (gl:new-list ourlist :compile)
      (macrolet ((wow (num start)
		   `(gl:vertex-attrib ,num
				      (aref verts (+ base (+ ,start 0)))
				      (aref verts (+ base (+ ,start 1)))
				      (aref verts (+ base (+ ,start 2)))
				      (aref verts (+ base (+ ,start 3)))))
		 (wow2 (num start)
		   `(gl:vertex-attrib ,num
				      (aref verts (+ base (+ ,start 0)))
				      (aref verts (+ base (+ ,start 1)))))
		 (wow3 (num start)
		   `(gl:vertex-attrib ,num
				      (aref verts (+ base (+ ,start 0)))
				      (aref verts (+ base (+ ,start 1)))
				      (aref verts (+ base (+ ,start 2)))))
		 (wow1 (num start)
		   `(gl:vertex-attrib ,num
				      (aref verts (+ base ,start)))))
	(gl:with-primitives :quads
	  (dotimes (x len)
	    (let ((base (* x vertsize)))
	      (wow1 8 5) ;darkness
	      (wow2 2 3) ;uv
	      ;;	    (wow 8 9)
	      ;;	    (wow 12 13)
	      (wow3 0 0) ;position
	      ))))
      (gl:end-list)
      ourlist)))

(defun getmeshersfinishedshit ()
  (multiple-value-bind (shape len coords) (sb-thread:join-thread mesher-thread)
    (if coords
	(if shape
	    (let ((old-call-list (get-chunk-display-list coords)))
	      (let ((new (shape-list shape len)))
		(if new
		    (set-chunk-display-list coords new)
		    (remove-chunk-display-list coords)))
	      (when old-call-list (gl:delete-lists old-call-list 1))
	      (let ((old-world (get-display-list :world)))
		(remove-display-list :world)
		(when old-world (gl:delete-lists old-world 1))))
	    (dirty-push coords))))
  (setf mesher-thread nil))

(defun mesherthreadbusy ()
  (not (or (eq nil mesher-thread)
	   (not (sb-thread:thread-alive-p mesher-thread)))))

(defun giveworktomesherThread (thechunk)
  (setf mesher-thread
	(sb-thread:make-thread
	 (lambda ()
	   (sb-thread:return-from-thread
	    (chunk-shape thechunk))))))
