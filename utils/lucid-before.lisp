;;; -*- Mode: LISP; Syntax: Common-Lisp; Package: LUCID; Base: 10 -*-
;;;
;;;; Lucid-before-patches, Module CLIM
;;;
;;; ***************************************************************************
;;;
;;;        Copyright (C) 1991 by Lucid, Inc.  All Rights Reserved
;;;
;;; ***************************************************************************
;;;
;;; Lucid specific hacks which need to be used by CLIM.
;;;
;;;
;;; Edit-History:
;;;
;;; Created: PW  2-Nov-91
;;;
;;;
;;; End-of-Edit-History


(in-package :lucid)

;;; $Id: lucid-before.lisp,v 2.4 2003/12/15 18:35:18 layer Exp $

;;; The advice is preventing the compiler from expanding it at compile time.
(remove-advice 'defstruct)

