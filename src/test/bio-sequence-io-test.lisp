;;;
;;; Copyright (C) 2007-2008, Keith James. All rights reserved.
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

(in-package :cl-bio-test)

(fiveam:in-suite cl-bio-system:testsuite)

;;; Test reading unambiguous/IUPAC Fasta DNA/RNA
;; (test read-bio-sequence/interface
;;   (with-open-file (fs (merge-pathnames "data/simple-dna1.fa")
;;                    :direction :input
;;                    :element-type '(unsigned-byte 8))
;;     (let ((stream (make-line-input-stream fs)))
;;       (signals error
;;         (read-bio-sequence stream :fasta :alphabet nil))
;;       (signals error
;;         (read-bio-sequence stream :fasta :alphabet :invalid-alphabet))
;;       (signals error
;;         (read-bio-sequence stream :fasta :alphabet :dna
;;                            :virtualp :invalid-virtualp)))))

(test bio-sequence-io/fasta/dna-simple
  (with-open-file (fs (merge-pathnames "data/simple-dna1.fa")
                   :direction :input
                   :element-type '(unsigned-byte 8))
    (let* ((stream (make-line-input-stream fs))
           (fn (make-input-fn stream :fasta :alphabet :dna))
           (seq (funcall fn)))
      (is (eql 'dna-sequence (type-of seq)))
      (is (eql (find-alphabet :dna) (alphabet-of seq)))
      (is-false (virtualp seq))
      (is (= 210 (length-of seq)))
      (is (string= "Test1" (identity-of seq))))))

(test bio-sequence-io/fasta/dna-simple/virtual
  (with-open-file (fs (merge-pathnames "data/simple-dna1.fa")
                   :direction :input
                   :element-type '(unsigned-byte 8))
    (let* ((stream (make-line-input-stream fs))
           (fn (make-input-fn stream :fasta :alphabet :dna :virtual t))
           (seq (funcall fn)))
      (is (eql 'dna-sequence (type-of seq)))
      (is (eql (find-alphabet :dna) (alphabet-of seq)))
      (is-true (virtualp seq))
      (is (= 210 (length-of seq)))
      (is (string= "Test1" (identity-of seq))))))

(test bio-sequence-io/fasta/dna-iupac
  (with-open-file (fs (merge-pathnames "data/iupac-dna1.fa")
                   :direction :input
                   :element-type '(unsigned-byte 8))
    (let* ((stream (make-line-input-stream fs))
           (fn (make-input-fn stream :fasta :alphabet :dna))
           (seq (funcall fn)))
      (is (eql 'dna-sequence (type-of seq)))
      (is (eql (find-alphabet :dna) (alphabet-of seq)))
      (is (= 210 (length-of seq)))
      (is (string= "Test1" (identity-of seq))))))

(test bio-sequence-io/multifasta/dna-simple
  (with-open-file (fs (merge-pathnames "data/simple-dna2.fa")
                   :direction :input
                   :element-type '(unsigned-byte 8))
    (let* ((stream (make-line-input-stream fs))
           (fn (make-input-fn stream :fasta :alphabet :dna)))
      (dotimes (n 2)
        (let ((seq (funcall fn)))
          (is (eql 'dna-sequence (type-of seq)))
          (is (eql (find-alphabet :dna) (alphabet-of seq)))
          (is (= 280 (length-of seq)))
          (is (string= (format nil "Test~a" (1+ n)) (identity-of seq)))))
      (is (null (funcall fn))))))

(test bio-sequence-io/multifasta/dna-simple/virtual
  (with-open-file (fs (merge-pathnames "data/simple-dna2.fa")
                   :direction :input
                   :element-type '(unsigned-byte 8))
    (let* ((stream (make-line-input-stream fs))
           (fn (make-input-fn stream :fasta :alphabet :dna :virtual t)))
      (dotimes (n 2)
        (let ((seq (funcall fn)))
          (is (eql 'dna-sequence (type-of seq)))
          (is (eql (find-alphabet :dna) (alphabet-of seq)))
          (is-true (virtualp seq))
          (is (= 280 (length-of seq)))
          (is (string= (format nil "Test~a" (1+ n)) (identity-of seq)))))
      (is (null (funcall fn))))))

(test bio-sequence-io/multifasta/dna-iupac
  (with-open-file (fs (merge-pathnames "data/iupac-dna2.fa")
                   :direction :input
                   :element-type '(unsigned-byte 8))
    (let* ((stream (make-line-input-stream fs))
           (fn (make-input-fn stream :fasta :alphabet :dna)))
      (dotimes (n 2)
        (let ((seq (funcall fn)))
          (is (eql 'dna-sequence (type-of seq)))
          (is (eql (find-alphabet :dna) (alphabet-of seq)))
          (is (= 280 (length-of seq)))
          (is (string= (format nil "Test~a" (1+ n)) (identity-of seq)))))
      (is (null (funcall fn))))))

(test bio-sequence-io/fastq/simple
  (with-open-file (fs (merge-pathnames "data/phred.fq")
                   :direction :input
                   :element-type '(unsigned-byte 8))
    (let* ((stream (make-line-input-stream fs))
           (fn (make-input-fn stream :fastq :alphabet :dna)))
      (do ((seq (funcall fn) (funcall fn)))
          ((null seq) t)
        (is (eql 'dna-quality-sequence (type-of seq)))
        (is (eql (find-alphabet :dna) (alphabet-of seq)))
        (is (= 35 (length-of seq)))
        (is (string= "IL13" (identity-of seq) :start2 0 :end2 4))))))

