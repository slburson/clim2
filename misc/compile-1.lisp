;; -*- mode: common-lisp; package: user -*-
;;
;;				-[Mon Jul 20 16:33:30 1998 by layer]-
;;
;; copyright (c) 1985, 1986 Franz Inc, Alameda, CA  All rights reserved.
;; copyright (c) 1986-1991 Franz Inc, Berkeley, CA  All rights reserved.
;;
;; The software, data and information contained herein are proprietary
;; to, and comprise valuable trade secrets of, Franz, Inc.  They are
;; given in confidence by Franz, Inc. pursuant to a written license
;; agreement, and may be stored and used only in accordance with the terms
;; of such license.
;;
;; Restricted Rights Legend
;; ------------------------
;; Use, duplication, and disclosure of the software, data and information
;; contained herein by any agency, department or entity of the U.S.
;; Government are subject to restrictions of Restricted Rights for
;; Commercial Software developed at private expense as specified in
;; DOD FAR Supplement 52.227-7013 (c) (1) (ii), as applicable.
;;
;; $Id: compile-1.lisp,v 1.33.22.6 1998/07/21 02:54:49 layer Exp $

(in-package :user)

;;;; This should not matter
;;;; (setq *ignore-package-name-case* t)

;; Forgive them, lord, for they know not what they do.
(pushnew :ansi-90 *features*)

(setq *print-case* :downcase)
(set-case-mode :case-insensitive-lower)

(setq comp:generate-call-count-code-switch
  (named-function |(> debug 1)|
		  (lambda (safety size speed debug)
		    (declare (ignore safety size speed))
		    (> debug 1))))

(setq comp:declared-fixnums-remain-fixnums-switch
  (named-function |(> speed 2)|
		  (lambda (safety size speed debug)
		    (declare (ignore safety size debug))
		    (> speed 2))))

(setf (sys:gsgc-parameter :print) t)

(defun compile-it (sys)
  (with-compilation-unit ()
    (let ((excl::*update-entry-points* nil))
      (unless (ignore-errors (excl:find-system 'sys))
	(load "clim2:;sys;sysdcl"))
      (excl:compile-system sys :include-components t)
      (tenuring
       (excl:load-system sys))

      (progn
	(excl:compile-system 'wnn :include-components t)
	(excl:load-system 'wnn))

      ;;(excl:compile-system 'clim-homegrown)

      (load "clim2:;postscript;sysdcl")
      (excl:compile-system 'postscript-clim :include-components t)
      (excl:load-system 'postscript-clim)

      (compile-file-if-needed "clim2:;test;test-suite")

      (load "clim2:;test;test-suite")

      (load "clim2:;demo;sysdcl")
      (excl:compile-system 'clim-demo :include-components t)
      (excl:load-system 'clim-demo)

      (progn
	(load "clim2:;test;testdcl")
	(tenuring
	 (excl:compile-system 'testing)
	 (excl:load-system 'testing)))

      (when (probe-file "clim2:;climtoys;sysdcl.lisp")
	(load "clim2:;climtoys;sysdcl.lisp")
	(excl:compile-system 'clim-toys))

;;;      (load "compatibility/sysdcl.lisp")
;;;      (excl:compile-system 'clim-compatibility :include-components t)

      (load "clim2:;hpgl;sysdcl")
      (excl:compile-system 'hpgl-clim :include-components t)
      (excl:load-system 'hpgl-clim))))

