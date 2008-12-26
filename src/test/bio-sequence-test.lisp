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

(in-package :cl-genomic-test)

(deftestsuite bio-sequence-tests (cl-genomic-tests)
  ())

;;; Alphabets
(addtest (bio-sequence-tests) find-alphabet/1
   (ensure-same bs::*dna* (find-alphabet :dna))
   (ensure-same bs::*rna* (find-alphabet :rna))
   (ensure-error
     (find-alphabet :foo)))

(addtest (bio-sequence-tests) standard-alphabets/1
  (mapc (lambda (alphabet tokens)
          (ensure (= (length tokens) (size-of alphabet)))
          (ensure
           (loop
              for token in tokens
              always (memberp alphabet token))))
        (mapcar #'find-alphabet '(:dna :rna))
        (mapcar (lambda (str)
                  (loop
                     for c across str collect c))
                (list dna-residues rna-residues))))

(addtest (bio-sequence-tests) alphabet/1
  (let ((name "test name"))
    (ensure (string= name
                     (name-of (make-instance 'alphabet :name name))))))

(addtest (bio-sequence-tests) alphabet/2
  (let ((tokens '(#\a #\b #\c #\d)))
    (ensure (equal tokens
                   (tokens-of (make-instance 'alphabet :tokens tokens))))))

;;; Sequence constructors
(addtest (bio-sequence-tests) make-dna/1
  (let ((seqs (list (make-dna "tagc")   ; unambiguous
                    (make-dna "nnnn"))) ; ambiguous
        (class-names (list 'dna-sequence
                           'dna-sequence))
        (alphabets (list (find-alphabet :dna)
                         (find-alphabet :dna))))
    (mapcar (lambda (seq class-name alphabet)
              (ensure (subtypep (class-name (class-of seq)) class-name))
              (ensure-same alphabet (alphabet-of seq)))
            seqs class-names alphabets))
  ;; We now allow empty sequences
  ;; (ensure-error
  ;;   (make-dna ""))
  (ensure-error
    (make-dna "u"))
  (ensure-error
    (make-dna '(#\t #\a #\g #\c))))

(addtest (bio-sequence-tests) make-dna/2
  (ensure (= 1 (num-strands-of (make-dna "tagc"))))
  (ensure (= 2 (num-strands-of (make-dna "tagc" :num-strands 2)))))

(addtest (bio-sequence-tests) make-dna/3
  (ensure (string= "nnnn" (coerce-sequence (make-dna nil :length 4) 'string))))

(addtest (bio-sequence-tests) make-rna/1
  (let ((seqs (list (make-rna "uagc") ; unambiguous
                    (make-rna "nnnn"))) ; ambiguous
        (class-names (list 'rna-sequence
                           'rna-sequence))
        (alphabets (list (find-alphabet :rna)
                         (find-alphabet :rna))))
    (mapcar (lambda (seq class-name alphabet)
              (ensure (subtypep (class-name (class-of seq)) class-name))
              (ensure-same alphabet (alphabet-of seq)))
            seqs class-names alphabets))
  ;; We now allow empty sequences
  ;; (ensure-error
  ;;   (make-dna ""))
  (ensure-error
    (make-rna "t"))
  (ensure-error
    (make-tna '(#\u #\a #\g #\c))))

(addtest (bio-sequence-tests) make-rna/2
  (ensure (= 1 (num-strands-of (make-rna "uagc"))))
  (ensure (= 2 (num-strands-of (make-rna "uagc" :num-strands 2)))))

(addtest (bio-sequence-tests) make-rna/3
  (ensure (string= "nnnn" (coerce-sequence (make-rna nil :length 4) 'string))))

(addtest (bio-sequence-tests) phred-quality/1
  (let ((pvals '(0.1 0.01 0.001 0.0001 0.00001))
        (quals '(10 20 30 40 50)))
    (loop
       for pval in pvals
       for qual in quals
       do (ensure-same qual (phred-quality pval)))))

(addtest (bio-sequence-tests) make-dna-quality/1
  (let ((seqs (list (make-dna-quality ; unambiguous
                     "agaatattctgaccccagttactttcaaga"
                     "<<<<<<<<<<<<<<<<<<<<<735513;3<"
                     :metric :phred)
                    (make-dna-quality ; ambiguous
                     "ntgccaaaaaatagaaaagtcancgatatt"
                     "<<<<<<<<<<<<<<<<<8<<<<<<5<3.5:"
                     :metric :phred)))
        (class-names (list 'dna-quality-sequence
                           'dna-quality-sequence)))
    (mapcar (lambda (seq class-name)
              (ensure (subtypep (class-name (class-of seq)) class-name)))
            seqs class-names))
  (ensure-error
    (make-dna-quality
     "agaatattctgaccccagttactttcaaga"
     "<<<<<<<"
     :metric :phred))
  (ensure-error
    (make-dna-quality
     "agaatattctgaccccagttactttcaaga"
     "<<<<<<<<<<<<<<<<<8<<<<<<5<3.5:"
     :metric :invalid-metric)))

;;; Utility methods
(addtest (bio-sequence-tests) simplep/1
  (ensure (simplep (find-alphabet :dna) "acgt"))
  (ensure (not (simplep (find-alphabet :dna) "acgn"))))

(addtest (bio-sequence-tests) simplep/2
  (ensure (simplep (find-alphabet :rna) "acgu"))
  (ensure (not (simplep (find-alphabet :rna) "acgn"))))

(addtest (bio-sequence-tests) anonymousp/1
  (ensure (anonymousp (make-dna "tagc")))
  (ensure (not (anonymousp (make-dna "tagc" :identity "test")))))

(addtest (bio-sequence-tests) single-stranded-p/1
  (let ((seq (make-dna "aaaaaaaaaa")))
    (ensure (single-stranded-p seq))))

(addtest (bio-sequence-tests) double-stranded-p/2
  (let ((seq (make-dna "aaaaaaaaaa" :num-strands 2)))
    (ensure (double-stranded-p seq))))

;;; Sequence accessors
(addtest (bio-sequence-tests) bio-sequence/1
  (let ((len 10))
    (ensure (= len (length-of (make-dna "aaaaaaaaaa"))))
    (ensure (= len (length-of (make-rna "aaaaaaaaaa"))))
    (ensure (= len (length-of (make-dna nil :length len))))
    (ensure (= len (length-of (make-rna nil :length len))))))

(addtest (bio-sequence-tests) bio-sequence/2
  (let* ((residues "aaggccttaaggcctt")
         (seq (make-dna residues)))
    (ensure (string= (subseq residues 0 5) ; aaggc
                     (coerce-sequence (subsequence seq 0 5) 'string)))
    (ensure (string= residues
                     (coerce-sequence (subsequence seq 0) 'string)))))

(addtest (bio-sequence-tests) bio-sequence/3
  (let ((seq (make-dna "aacccgggt")))
    (mapc (lambda (token freq)
            (ensure (eq (cdr (assoc token (residue-frequencies
                                           seq
                                           (find-alphabet :dna))
                                    :test #'char= )) freq)))
          '(#\a #\c #\g #\t)
          '(2 3 3 1))))

(addtest (bio-sequence-tests) na-sequence/1
  (let ((ss-seq (make-dna "aaaaaaaaaa"))
        (ds-seq (make-dna "aaaaaaaaaa" :num-strands 2)))
    (ensure (= 1 (num-strands-of ss-seq)))
    (ensure (= 2 (num-strands-of ds-seq)))))

(addtest (bio-sequence-tests) dna-sequence/1
  (let ((residues "tttt")
        (seq (make-dna "aaaa")))
    (dotimes (n (length residues))
      (setf (residue-of seq n) (aref residues n))
      (ensure (char= (residue-of seq n) (aref residues n))))))

(addtest (bio-sequence-tests) dna-sequence/2
  (let* ((residues "acgt")
         (seq (make-dna residues)))
    ;; no args
    (ensure (string= residues (coerce-sequence seq 'string)))
    ;; optional arg start
     (dotimes (n 4)
       (ensure (string= (subseq residues n)
                        (coerce-sequence seq 'string :start n))))
     (dotimes (n 4)
       (ensure (string= (subseq residues 0 n)
                        (coerce-sequence seq 'string :start 0 :end n))))))

(addtest (bio-sequence-tests) dna-sequence/3
  (let* ((residues "aaccggtt")
         (seq (make-dna residues)))
    (ensure (string= (coerce-sequence (reverse-sequence seq) 'string)
                     (reverse residues)))))

(addtest (bio-sequence-tests) dna-sequence/4
  (let* ((residues "aaccggtt")
         (seq (make-dna residues)))
    (ensure (string= (coerce-sequence (nreverse-sequence seq) 'string)
                     (reverse residues)))))

(addtest (bio-sequence-tests) dna-sequence/5
  (let ((seq (make-dna dna-residues)))
    (ensure (string= "atcgyrmkswvhdbn-"
                     (coerce-sequence (complement-sequence seq) 'string)))))

(addtest (bio-sequence-tests) dna-sequence/6
  (let ((seq (make-dna dna-residues)))
    (ensure (string= "-nbdhvwskmrygcta"
                     (coerce-sequence (reverse-complement seq) 'string)))))

(addtest (bio-sequence-tests) dna-sequence/7
  (let ((seq (make-dna dna-residues)))
    (ensure (string= "-nbdhvwskmrygcta"
                     (coerce-sequence (nreverse-complement seq) 'string)))))

(addtest (bio-sequence-tests) rna-sequence/1
  (let ((residues "uuuu")
        (rna-seq (make-rna "aaaa")))
    (dotimes (n (length residues))
      (setf (residue-of rna-seq n) (aref residues n))
      (ensure (char= (residue-of rna-seq n) (aref residues n))))))

(addtest (bio-sequence-tests) rna-sequence/2
  (let* ((residues "acgu")
         (seq (make-rna residues)))
    ;; no args
    (ensure (string= residues (coerce-sequence seq 'string)))
    ;; optional arg start
    (dotimes (n 4)
      (ensure (string= (subseq residues n)
                       (coerce-sequence seq 'string :start n))))
    (dotimes (n 4)
      (ensure (string= (subseq residues 0 n)
                       (coerce-sequence seq 'string :start 0 :end n))))))

(addtest (bio-sequence-tests) virtual-dna-sequence/1
  (let* ((len 10)
         (seq (make-dna nil :length 10)))
    (dotimes (n len)
      (ensure (char= #\n (residue-of seq n))))
    (ensure-error 'invalid-argument-error
      (residue-of seq -1))
    (ensure-error 'invalid-argument-error
      (residue-of seq 11))))

(addtest (bio-sequence-tests) dna-quality-sequence/3
  (let* ((residues "agaatattctgaccccagttactttcaaga")
         (quality "<<<<<<<<<<<<<<<<<<<<<735513;3<")
         (seq (make-dna-quality residues quality :metric :phred))
         (rseq (reverse-sequence seq)))
    (ensure (string= (coerce-sequence rseq 'string)
                     (reverse residues)))
    (ensure (string= (reverse quality)
                     (map-into (make-string (length residues))
                               #'encode-phred-quality
                               (quality-of rseq))))))

(addtest (bio-sequence-tests) dna-quality-sequence/4
  (let* ((residues "agaatattctgaccccagttactttcaaga")
         (quality "<<<<<<<<<<<<<<<<<<<<<735513;3<")
         (rresidues (reverse residues))
         (rquality (reverse quality))
         (seq (make-dna-quality residues quality :metric :phred))
         (rseq (nreverse-sequence seq)))
    (ensure (string= rresidues (coerce-sequence rseq 'string)))
    (ensure (equalp rquality
                    (map-into (make-string (length residues))
                              #'encode-phred-quality
                              (quality-of rseq))))))

(addtest (bio-sequence-tests) dna-quality-sequence/5
  (let* ((residues "agaatattctgaccccagttactttcaaga")
         (quality "<<<<<<<<<<<<<<<<<<<<<735513;3<")
         (seq (make-dna-quality residues quality :metric :phred)))
    (ensure (string= "tcttataagactggggtcaatgaaagttct"
                     (coerce-sequence (complement-sequence seq) 'string)))
    (ensure (string= quality
                     (map-into (make-string (length residues))
                               #'encode-phred-quality
                               (quality-of seq))))))

(addtest (bio-sequence-tests) dna-quality-sequence/6
  (let* ((residues "agaatattctgaccccagttactttcaaga")
         (quality "<<<<<<<<<<<<<<<<<<<<<735513;3<")
         (rquality (reverse quality))
         (seq (make-dna-quality residues quality :metric :phred)))
    (ensure (string= "tcttgaaagtaactggggtcagaatattct"
                     (coerce-sequence (reverse-complement seq) 'string)))
    (let ((rcquality (quality-of (reverse-complement seq))))
      (ensure (string= rquality
                       (map-into (make-string (length residues))
                                 #'encode-phred-quality rcquality))))))

(addtest (bio-sequence-tests) dna-quality-sequence/7
  (let* ((residues "agaatattctgaccccagttactttcaaga")
         (quality "<<<<<<<<<<<<<<<<<<<<<735513;3<")
         (rquality (reverse quality))
         (seq (make-dna-quality residues quality :metric :phred))
         (rseq (nreverse-complement seq)))
    (ensure (string= "tcttgaaagtaactggggtcagaatattct"
                     (coerce-sequence rseq 'string)))
    (let ((rcquality (quality-of rseq)))
      (ensure (string= rquality
                       (map-into (make-string (length residues))
                                 #'encode-phred-quality rcquality))))))

(addtest (bio-sequence-tests) dna-quality-sequence/8
  (let* ((residues "agaatattctgaccccagttactttcaaga")
         (quality "<<<<<<<<<<<<<<<<<<<<<735513;3<")
         (seq (make-dna-quality residues quality :metric :phred)))
    (ensure (string= (subseq residues 0 5)
                     (coerce-sequence (subsequence seq 0 5) 'string)))
    (loop
       for q across (quality-of (subsequence seq 0 5))
       do (ensure (= 27 q)))))

(addtest (bio-sequence-tests) virtual-token-sequence/3
  (let ((seq (make-dna nil :length 10)))
    (ensure (eql (class-of seq) (class-of (reverse-sequence seq))))
    (ensure (= 10 (length-of (reverse-sequence seq))))))

(addtest (bio-sequence-tests) virtual-token-sequence/4
  (let ((seq (make-dna nil :length 10)))
    (ensure (eql (class-of seq) (class-of (reverse-sequence seq))))
    (ensure (= 10 (length-of (reverse-sequence seq))))))

(addtest (bio-sequence-tests) virtual-token-sequence/5
  (let ((seq (make-dna nil :length 10)))
    (ensure (eql (class-of seq) (class-of (complement-sequence seq))))
    (ensure (= 10 (length-of (complement-sequence seq))))))

(addtest (bio-sequence-tests) virtual-token-sequence/6
  (let ((seq (make-dna nil :length 10)))
    (ensure (eql (class-of seq) (class-of (reverse-complement seq))))
    (ensure (= 10 (length-of (reverse-complement seq))))))

(addtest (bio-sequence-tests) virtual-token-sequence/7
  (let ((seq (make-dna nil :length 10)))
    (ensure (eql (class-of seq) (class-of (nreverse-complement seq))))
    (ensure (= 10 (length-of (nreverse-complement seq))))))

(addtest (bio-sequence-tests) virtual-token-sequence/8
  (let ((seq (make-dna nil :length 10)))
    (ensure (= 5 (length-of (subsequence seq 0 5))))
    (ensure (= 10 (length-of (subsequence seq 0))))))

(addtest (bio-sequence-tests) search-sequence/1
  (let ((seq (make-dna "tacgagtcgttttagcgcgattatataa"))
        (sub (make-dna "gtttt")))
    (ensure (= 8 (search-sequence sub seq)))
    (ensure (= 9 (search-sequence sub seq :start1 1)))
    (ensure (= 8 (search-sequence sub seq :start2 1)))
    (ensure (= 3 (search-sequence sub seq :end1 1)))
    (ensure-null (search-sequence sub seq :end2 1))))
