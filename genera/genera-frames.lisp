;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Package: GENERA-CLIM; Base: 10; Lowercase: Yes -*-

;; $fiHeader: genera-frames.lisp,v 1.12 92/10/02 15:20:24 cer Exp $

(in-package :genera-clim)

"Copyright (c) 1992 Symbolics, Inc.  All rights reserved."


(defparameter *use-gadget-menu-bars* nil)
(defclass genera-frame-manager (standard-frame-manager)
    ((gadget-menu-bar :initarg :gadget-menu-bar :initform *use-gadget-menu-bars*))
  (:default-initargs :dialog-view +textual-dialog-view+))

(defmethod make-frame-manager ((port genera-port) 
			       &key palette (gadget-menu-bar *use-gadget-menu-bars*)
			       &allow-other-keys)
  (make-instance 'genera-frame-manager 
    :port port :palette palette :gadget-menu-bar gadget-menu-bar))

(defmethod frame-manager-matches-options-p
	   ((framem genera-frame-manager) port 
	    &key palette (gadget-menu-bar *use-gadget-menu-bars*) &allow-other-keys)
  (and (eq (port framem) port)
       (eq (slot-value framem 'gadget-menu-bar) gadget-menu-bar)))

(defmethod frame-wrapper ((framem genera-frame-manager) 
			  (frame standard-application-frame) pane)
  (let* ((menu-pane (clim-internals::find-frame-pane-of-type 
		      frame 'clim-internals::command-menu-pane))
	 (menu-bar (let ((menu-bar (slot-value frame 'menu-bar)))
		     (cond ((and menu-pane (eq menu-bar 't)) nil)
			   ((eq menu-bar 't) (frame-command-table frame))
			   (t menu-bar)))))
    (with-look-and-feel-realization (framem frame)
      (outlining ()
	(if menu-bar
	    (vertically ()
	      (if (slot-value framem 'gadget-menu-bar)
		  (compute-menu-bar-pane frame menu-bar)
		  (outlining ()
		    (make-pane 'command-menu-pane
		      :display-function 
		        `(display-command-menu :command-table ,menu-bar)
		      :incremental-redisplay t
		      :default-text-style clim-internals::*command-table-menu-text-style*
		      :text-style clim-internals::*command-table-menu-text-style*
		      :width :compute :height :compute)))
	      pane)
	    pane)))))

(defmethod frame-manager-exit-box-labels 
	   ((framem genera-frame-manager) frame view)
  (declare (ignore frame view))
  '((:exit   "<End> uses these values")
    (:abort  "<Abort> aborts")))

(defmethod frame-manager-exit-box-labels
	   ((framem genera-frame-manager) frame (view gadget-dialog-view))
  (declare (ignore frame))
  '((:exit   "Exit")
    (:abort  "Cancel")))


;;; Pointer documentation and progress notes for Genera

(defmacro with-who-line-stream ((stream-var frame field) &body body)
  `(let ((,stream-var
	  (let* ((console (tv:sheet-console (sheet-mirror (graft ,frame))))
		 (who-screen (if (eq console sys:*main-console*)
				 tv:who-line-screen
				 (tv:console-who-line-screen console))))
	    (and who-screen
		 (tv:get-who-line-field ,field)))))
     ,@body))

(defmethod frame-manager-clear-progress-note 
	   ((framem genera-frame-manager) (note clim-internals::progress-note))
  (with-who-line-stream (stream (slot-value note 'clim-internals::frame) :file-state)
    (when stream
      (scl:send stream :clear-window))))

(defmethod frame-manager-display-progress-note
	   ((framem genera-frame-manager) (note clim-internals::progress-note))
  (with-who-line-stream (stream (slot-value note 'clim-internals::frame) :file-state)
    (with-slots clim-internals::(name-displayed bar-length) note
      (when stream
	(let* ((stream-width (scl:send stream :inside-width))
	       (line-height  (- (scl:send stream :inside-height) 2))
	       (new-bar-length 
		 (floor (* stream-width (slot-value note 'clim-internals::numerator))
			(slot-value note 'clim-internals::denominator))))
	  (unless clim-internals::name-displayed
	    (scl:send stream :clear-window))
	  (unless clim-internals::name-displayed
	    (scl:send stream :set-cursorpos 0 0)
	    (scl:send stream :string-out (progress-note-name note))
	    (setq clim-internals::name-displayed t))
	  (when (< new-bar-length clim-internals::bar-length)
	    (scl:send stream :draw-rectangle
			     clim-internals::bar-length 2 0 line-height :erase))
	  (scl:send stream :draw-rectangle new-bar-length 2 0 line-height :draw)
	  (setq clim-internals::bar-length new-bar-length))))))


(defvar *pointer-documentation-buffer*
	(make-array 80 :element-type 'string-char :fill-pointer 0 :adjustable t))

(defmethod frame-manager-display-pointer-documentation
	   ((framem genera-frame-manager)
	    frame presentation input-context window x y stream)
  (declare (ignore stream))
  (let ((stream
	  (let ((console (tv:sheet-console (sheet-mirror (graft frame)))))
	    (if (eq console sys:*main-console*)
		tv:who-line-documentation-window
		(let ((who-screen (tv:console-who-line-screen console)))
		  (and who-screen
		       (tv:get-who-line-field :mouse-documentation who-screen)))))))
    ;; The documentation should never say anything if we're not over a presentation
    (when (null presentation) 
      (scl:send stream :clear-window))
    ;; Cheap test to not do this work too often
    (let ((old-modifier-state clim-internals::*last-pointer-documentation-modifier-state*)
	  (modifier-state (clim-internals::window-modifier-state window))
	  (last-time clim-internals::*last-pointer-documentation-time*)
	  (time (get-internal-real-time)))
      (setq clim-internals::*last-pointer-documentation-modifier-state* modifier-state)
      (when (and (< time (+ last-time clim-internals::*pointer-documentation-interval*))
		 (= modifier-state old-modifier-state))
	(return-from clim-internals::frame-manager-display-pointer-documentation nil))
      (setq clim-internals::*last-pointer-documentation-time* time))
    (when presentation
      (setf (fill-pointer *pointer-documentation-buffer*) 0)
      (with-output-to-string (stream *pointer-documentation-buffer*)
	(when (null (clim-internals::frame-document-highlighted-presentation-1
		      frame presentation input-context window x y stream))
	  (setq clim-internals::*last-pointer-documentation-time* 0)))
      (scl:send stream :clear-window)
      (scl:send stream :string-out *pointer-documentation-buffer*))))
