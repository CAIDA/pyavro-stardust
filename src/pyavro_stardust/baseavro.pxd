# This software is Copyright (C) 2021 The Regents of the University of
# California. All Rights Reserved. Permission to copy, modify, and distribute
# this software and its documentation for educational, research and non-profit
# purposes, without fee, and without a written agreement is hereby granted,
# provided that the above copyright notice, this paragraph and the following
# three paragraphs appear in all copies. Permission to make commercial use of
# this software may be obtained by contacting:
#
# Office of Innovation and Commercialization
# 9500 Gilman Drive, Mail Code 0910
# University of California
# La Jolla, CA 92093-0910
# (858) 534-5815
# invent@ucsd.edu
#
# This software program and documentation are copyrighted by The Regents of the
# University of California. The software program and documentation are supplied
# "as is", without any accompanying services from The Regents. The Regents does
# not warrant that the operation of the program will be uninterrupted or
# error-free. The end-user understands that the program was developed for
# research purposes and is advised not to rely exclusively on the program for
# any reason.
#
# IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING
# LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION,
# EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE. THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED
# HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO
# OBLIGATIONS TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
# MODIFICATIONS.

from libcpp.vector cimport vector
from cpython cimport array
import array


cdef struct parsedString:
    unsigned int toskip
    unsigned int strlen
    unsigned char *start

cdef struct parsedNumericArrayBlock:
    unsigned int totalsize
    unsigned int blockcount
    long *values


cdef (unsigned int, long) read_long(const unsigned char[:] buf,
        const unsigned int maxlen)
cdef parsedString read_string(const unsigned char[:] buf,
        const unsigned int maxlen, int addNullTerm=*)

cdef parsedNumericArrayBlock read_numeric_array(const unsigned char[:] buf,
        const unsigned int maxlen)

cdef class AvroRecord:

    cdef long *attributes_l
    cdef char **attributes_s
    cdef long **attributes_na
    cdef long *attributes_na_sizes
    cdef unsigned int sizeinbuf
    cdef unsigned int stringcount
    cdef unsigned int numcount
    cdef unsigned int numarraycount

    cdef int parseNumeric(self, const unsigned char[:] buf,
        const unsigned int maxlen, const int attrind)
    cpdef long getNumeric(self, const int attrind)
    cpdef str getString(self, const int attrind)
    cdef unsigned int getRecordSizeInBuffer(self)
    cdef unsigned int parseNumericArray(self, const unsigned char[:] buf,
            const unsigned int maxlen, const int attrind)
    cdef unsigned int parseString(self, const unsigned char[:] buf,
            const unsigned int maxlen, const int attrind)
    cpdef vector[long] getNumericArray(self, const int attrind)
    cpdef void resetRecord(self)


cdef class AvroReader:
    cdef unsigned int nextblock
    cdef unsigned int unzip_offset
    cdef fh
    cdef str filepath
    cdef bytearray syncmarker
    cdef bytearray bufrin
    cdef bytes unzipped
    cdef AvroRecord currentrec
    cdef dict schemajson

    cpdef void _readAvroFileHeader(self)
    cdef int _parseNextRecord(self, const unsigned char[:] buf,
                 const unsigned int maxlen)
    cdef AvroRecord _getNextRecord(self)
    cpdef void perAvroRecord(self, func, userarg=*)

# vim: set sw=4 tabstop=4 softtabstop=4 expandtab :
