;;;
;;; Copyright (c) 2007-2011 Keith James. All rights reserved.
;;;
;;; This file is part of cl-genomic.
;;;
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;;

(in-package :bio-sequence)

;;; Default methods which ignore all data from the parser
(defmethod begin-object ((parser bio-sequence-parser))
  nil)

(defmethod object-alphabet ((parser bio-sequence-parser) alphabet)
  nil)

(defmethod object-identity ((parser bio-sequence-parser) identity)
  nil)

(defmethod object-residues ((parser bio-sequence-parser) residues)
  nil)

(defmethod end-object ((parser bio-sequence-parser))
  nil)

;;; Collecting raw data into Lisp objects
(defmethod begin-object :before ((parser raw-sequence-parser))
  (with-accessors ((raw parsed-raw-of))
      parser
    (setf raw ())))

(defmethod object-alphabet ((parser raw-sequence-parser) alphabet)
  (with-accessors ((raw parsed-raw-of))
      parser
    (setf raw (acons :alphabet alphabet raw))))

(defmethod object-identity ((parser raw-sequence-parser) (identity string))
  (with-accessors ((raw parsed-raw-of))
      parser
    (setf raw (acons :identity identity raw))))

(defmethod object-description ((parser raw-sequence-parser)
 (description string))
  (with-accessors ((raw parsed-raw-of))
      parser
    (setf raw (acons :description description raw))))

(defmethod object-residues ((parser raw-sequence-parser) (residues string))
  (with-accessors ((raw parsed-raw-of))
      parser
    (let ((vec (assocdr :residues raw))) 
      (if vec
          (vector-push-extend residues vec)
          (setf raw (acons :residues
                           (make-array 1 :adjustable t :fill-pointer t
                                       :initial-element residues) raw))))))

(defmethod object-quality ((parser raw-sequence-parser) (quality string))
  (with-accessors ((raw parsed-raw-of))
      parser
    (let ((vec (assocdr :quality raw))) 
      (if vec
          (vector-push-extend quality vec)
        (setf raw (acons :quality
                         (make-array 1 :adjustable t :fill-pointer t
                                     :initial-element quality) raw))))))

(defmethod end-object ((parser raw-sequence-parser))
  (with-accessors ((raw parsed-raw-of))
      parser
    (dolist (key '(:residues :quality))
      (let ((val (assocdr key raw)))
        (when (and val (not (stringp val)))
          (setf (assocdr key raw) (concat-strings val)))))
    raw))

;;; Collecting data into CLOS instances
(defmethod begin-object :before ((parser simple-sequence-parser))
  (with-accessors ((identity parsed-identity-of)
                   (description parsed-description-of)
                   (residues parsed-residues-of))
      parser
    (setf identity nil
          description nil
          residues (make-array 0 :adjustable t :fill-pointer 0))))

(defmethod object-alphabet ((parser simple-sequence-parser) alphabet)
  (setf (parsed-alphabet-of parser) alphabet))

(defmethod object-identity ((parser simple-sequence-parser) (identity string))
  (setf (parsed-identity-of parser) identity))

(defmethod object-description ((parser simple-sequence-parser)
                               (description string))
  (setf (parsed-description-of parser) description))

(defmethod object-residues ((parser simple-sequence-parser) (residues vector))
  (vector-push-extend residues (parsed-residues-of parser)))

(defmethod end-object ((parser simple-sequence-parser))
  (make-bio-sequence parser))

;;; Collecting data into CLOS instances with quality
(defmethod begin-object :before ((parser quality-sequence-parser))
  (with-accessors ((quality parsed-quality-of))
      parser
    (setf quality (make-array 0 :adjustable t :fill-pointer 0))))

(defmethod object-quality ((parser quality-sequence-parser) (quality vector))
  (vector-push-extend quality (parsed-quality-of parser)))


;;; Collecting data into CLOS instances without explicit residues
(defmethod begin-object :before ((parser virtual-sequence-parser))
  (with-accessors ((length parsed-length-of))
      parser
    (setf length 0)))

(defmethod object-residues ((parser virtual-sequence-parser) (residues vector))
  (incf (parsed-length-of parser) (length residues)))

;;; Writing data to a stream
(defmethod object-residues ((parser streaming-parser) (residues vector))
  (princ residues (stream-of parser)))

;;; Collecting data into an indexed file that may be mmapped later
(defmethod object-residues :after ((parser indexing-sequence-parser)
                                   (residues vector))
  (princ residues (stream-of parser)))

(defmethod end-object :after ((parser indexing-sequence-parser))
  (with-accessors ((offset offset-of) (length parsed-length-of))
      parser
    (incf offset length)))

;;; CLOS instance constructors
(defmethod make-bio-sequence ((parser simple-sequence-parser))
   (with-accessors ((identity parsed-identity-of)
                    (description parsed-description-of)
                    (alphabet parsed-alphabet-of)
                    (chunks parsed-residues-of))
       parser
     (check-record (plusp (length chunks)) identity
                   "no sequence residue data provided")
     (let ((constructor (ecase alphabet
                          (:dna #'make-dna)
                          (:rna #'make-rna)
                          (:aa #'make-aa)))
           (residues (with-output-to-string (s)
                       (loop
                          for chunk across chunks
                          do (write-string chunk s)))))
      (funcall constructor residues :identity identity
               :description description))))

(defmethod make-bio-sequence ((parser virtual-sequence-parser))
  (with-accessors ((identity parsed-identity-of)
                   (description parsed-description-of)
                   (alphabet parsed-alphabet-of)
                   (length parsed-length-of))
      parser
    (let ((class (ecase alphabet
                   (:dna 'virtual-dna-sequence)
                   (:rna 'virtual-rna-sequence)
                   (:aa 'virtual-aa-sequence))))
      (make-instance class :identity identity :description description
                     :length length))))

(defmethod make-bio-sequence ((parser quality-sequence-parser))
  (with-accessors ((identity parsed-identity-of)
                   (description parsed-description-of)
                   (alphabet parsed-alphabet-of)
                   (residue-chunks parsed-residues-of)
                   (quality-chunks parsed-quality-of)
                   (metric parsed-metric-of))
      parser
    (check-record (plusp (length residue-chunks)) identity
                  "no sequence residue data provided")
    (check-record (plusp (length quality-chunks)) identity
                  "no quality data provided")
    (flet ((maybe-concat (chunks)
             (if (= 1 (length chunks))
                 (aref chunks 0)
                 (with-output-to-string (s)
                   (loop
                      for chunk across chunks
                      do (write-string chunk s))))))
      (let ((constructor (ecase alphabet
                           (:dna 'make-dna-quality)))
            (residues (maybe-concat residue-chunks))
            (quality (maybe-concat quality-chunks)))
        (funcall constructor residues quality :identity identity
                 :description description :metric metric)))))

(defmethod make-seq-input ((stream stream) format &rest args)
  (let ((s (make-line-stream stream)))
    (apply #'make-seq-input s format args)))

(defmacro with-seq-input ((seqi filespec format &rest args) &body body)
  (with-gensyms (stream)
    `(with-open-file (,stream ,filespec
                              :element-type 'base-char :external-format :ascii)
       (let ((,seqi (make-seq-input ,stream ,format ,@args)))
         ,@body))))

(defmacro with-seq-output ((seqo filespec format &rest args) &body body)
  (with-gensyms (stream)
    `(with-open-file (,stream ,filespec :direction :output
                              :element-type 'base-char :external-format :ascii
                              :if-exists :supersede)
      (let ((,seqo (make-seq-output ,stream ,format ,@args)))
        ,@body))))

(defmacro with-mapped-dna ((seq &key filespec delete length) &body body)
  (with-gensyms (fsize len)
    `(progn
       (check-arguments (or ,filespec ,length) (,filespec ,length)
                        "either filespec or length must be provided")
       (let ((,len (if ,filespec
                       (let ((,fsize (with-open-file (s ,filespec)
                                       (file-length s))))
                         (cond (,length
                                (check-arguments (<= ,length ,fsize)
                                                 (,filespec ,length)
                                                 "requested length too large")
                                ,length)
                               (t
                                ,fsize)))
                     ,length)))
         (dxn:with-mapped-vector (,seq 'mapped-dna-sequence
                                       :filespec ,filespec :delete ,delete
                                       :length ,len)
           ,@body)))))

(defun skip-malformed-sequence (condition)
  "Restart function that invokes the SKIP-SEQUENCE-RECORD restart to
skip over a malformed sequence record."
  (declare (ignore condition))
  (invoke-restart 'skip-sequence-record))

(defun split-from-generator (input-gen writer n pathname-gen)
  "Reads raw sequence records from function INPUT-GEN and writes up to
N of them into a series of new files using function WRITER. The new
files names are denoted by filespecs read from function
PATHNAME-GEN. Returns when INPUT-GEN is exhausted."
  (loop
     for num-written = (write-n-raw-sequences
                        input-gen writer n (funcall pathname-gen))
     until (zerop num-written)))

(defun write-n-raw-sequences (input-gen writer n pathname)
  "Reads up to N raw sequence records by calling closure INPUT-GEN and
writes them into a new file of PATHNAME. Returns the number of records
actually written, which may be 0 if STREAM contained no further
records. WRITER is a function capable of writing an alist of raw data
contain keys and values as created by {defclass raw-sequence-parser} ,
for example, {defun write-raw-fasta} and {defun write-raw-fastq} ."
  (declare (optimize (speed 3)))
  (declare (type function writer)
           (type fixnum n))
  (check-arguments (plusp n) (n) "n must be a positive number")
  (let ((num-written
         (with-open-file (out pathname :direction :output
                          :if-exists :supersede
                          :element-type 'base-char
                          :external-format :ascii)
           (loop
              for count of-type fixnum from 0 below n
              for raw = (next input-gen)
              while raw
              do (funcall writer raw out)
              finally (return count)))))
    (when (zerop num-written)
      (delete-file pathname))
    num-written))

(declaim (inline nadjust-case))
(defun nadjust-case (string token-case)
  "Returns STRING, having destructively modified the case of its
characters as indicated by TOKEN-CASE, which may be :UPPER, :LOWER or
NIL. Specifying a TOKEN-CASE of NIL results in the original string
case being retained."
  (ecase token-case
    ((nil) string)
    (:lower (nstring-downcase string))
    (:upper (nstring-upcase string))))
