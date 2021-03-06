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

(defclass bio-sequence-parser ()
  ()
  (:documentation "The base class of all biological sequence
parsers. The default methods specialised on this class are all no-ops,
ignoring any data and returning NIL. The role of bio-sequence-parser
objects is to act as a place for storing state during parsing,
particularly when reading from streams."))

(defclass quality-parser-mixin ()
  ((metric :initform nil
           :initarg :metric
           :accessor parsed-metric-of
           :documentation "The quality metric, e.g. :sanger ,
:illumina , parsed from the input stream. The metric is used to
determine the quality decoding function. The Fastq file format was
finally codified in Nucleic Acids Research, 2009, 1-5
doi:10.1093/nar/gkp1137. The variants described therein as
fastq-sanger, fastq-solexa and fastq-illumina are adopted here as
quality metrics :sanger , :solexa and :illumina respectively."))
  (:documentation "A parser specialised for processing biological
sequence data with additional residue quality information."))

(defclass raw-sequence-parser (quality-parser-mixin
                               bio-sequence-parser)
  ((raw :initform ()
        :accessor parsed-raw-of
        :documentation "The raw sequence data parsed from the input
stream."))
  (:documentation "A parser specialised for processing raw biological
sequence data. This class is typically used for simple reformatting,
splitting or counting operations where making CLOS objects is not
desirable."))

(defclass simple-sequence-parser (bio-sequence-parser)
  ((alphabet :initform nil
             :accessor parsed-alphabet-of
             :documentation "The sequence alphabet designator,
e.g. :dna, :rna, parsed from the input stream.")
   (identity :initform nil
             :accessor parsed-identity-of
             :documentation "The sequence identity parsed from the
input stream.")
   (description :initform nil
                :accessor parsed-description-of
                :documentation "The sequence documentation parsed from
the input stream.")
   (residues :initform (make-array 0 :adjustable t :fill-pointer 0)
             :accessor parsed-residues-of
             :documentation "The sequence residues parsed from the
input stream."))
  (:documentation "A parser specialised for processing biological
sequence data to build CLOS objects."))

(defclass quality-sequence-parser (quality-parser-mixin
                                   simple-sequence-parser)
  ((quality :initform (make-array 0 :adjustable t :fill-pointer 0)
            :accessor parsed-quality-of
            :documentation "The sequence quality data parsed from the
input stream."))
  (:documentation "A parser specialised for processing biological
sequence data with quality to build CLOS objects."))

(defclass virtual-sequence-parser (simple-sequence-parser)
  ((length :initform 0
           :accessor parsed-length-of
           :documentation "The sequence length parsed from the input
stream."))
  (:documentation "A parser specialised for processing biological
sequence data to build CLOS objects that do not contain explicit
residue data."))

(defclass streaming-parser (virtual-sequence-parser)
  ((stream :initarg :stream
           :reader stream-of)))

(defclass indexing-sequence-parser (streaming-parser)
  ((offset :initform 0
           :accessor offset-of)))

(defclass gff3-parser (bio-sequence-parser)
  ((feature-ontology)
   (attribute-ontology)
   (source-ontology)
   (sequence-regions)))
