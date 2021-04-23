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

# cython: language_level=3
from libc.string cimport memcpy
from libcpp.vector cimport vector
from cpython.mem cimport PyMem_Malloc, PyMem_Free, PyMem_Realloc
import zlib, wandio, sys, json
cimport cython

cdef (unsigned int, long) read_long(const unsigned char[:] buf,
        const unsigned int maxlen):
    cdef unsigned int longlen = 0
    cdef unsigned int shift
    cdef unsigned long b
    cdef unsigned long n

    if maxlen == 0:
        return 0,0

    b = buf[0]
    n = b & 0x7F
    shift = 7

    while (b & 0x80) != 0:
        longlen += 1
        if longlen >= maxlen:
            return 0,0
        b = buf[longlen] 
        n |= ((b & 0x7F) << shift)
        shift += 7


    return (longlen + 1, (n >> 1) ^ -(n & 1))

cdef parsedString read_string(const unsigned char[:] buf,
        const unsigned int maxlen, int addNullTerm=True):

    cdef unsigned int skip
    cdef long strlen
    cdef parsedString s

    skip,strlen = read_long(buf, maxlen)
    if skip == 0:
        s.toskip = 0
        s.strlen = 0
        s.start = NULL
        return s

    s.toskip = skip
    s.strlen = strlen

    if addNullTerm:
        s.start = <unsigned char *>PyMem_Malloc(strlen + 1)
        memcpy(s.start, &(buf[skip]), strlen)
        s.start[strlen] = b'\x00'
    else:
        s.start = <unsigned char *>PyMem_Malloc(strlen)
        memcpy(s.start, &(buf[skip]), strlen)

    return s

cdef parsedNumericArrayBlock read_numeric_array(const unsigned char[:] buf,
        const unsigned int maxlen):
    cdef unsigned int skip
    cdef long arrayitem, blockcount
    cdef parsedNumericArrayBlock arr

    skip, blockcount = read_long(buf, maxlen)
    if skip == 0:
        arr.totalsize = 0
        arr.blockcount = 0
        arr.values = NULL
        return arr

    arr.totalsize = skip
    arr.blockcount = 0

    if blockcount == 0:
        arr.values = NULL
        return arr

    arr.values = <long *>PyMem_Malloc(sizeof(long) * arr.blockcount)

    for i in range(blockcount):
        skip, arrayitem = read_long(buf[arr.totalsize:], maxlen - arr.totalsize)
        if skip == 0:
            break
        arr.totalsize += skip
        arr.values[arr.blockcount] = arrayitem
        arr.blockcount += 1

    return arr

cdef class AvroRecord:

    def __cinit__(self):
        self.attributes_l = NULL
        self.attributes_s = NULL
        self.attributes_na = NULL
        self.attributes_na_sizes = NULL;
        self.stringcount = 0
        self.numcount = 0
        self.numarraycount = 0

    def __init__(self, numeric, strings, numarrays):
        cdef unsigned int i
        if (numeric > 0):
            self.attributes_l = <long *>PyMem_Malloc(sizeof(long) * numeric)
            for i in range(numeric):
                self.attributes_l[i] = 0
            self.numcount = numeric

        if (strings > 0):
            self.attributes_s = <char **>PyMem_Malloc(sizeof(char *) * strings)
            for i in range(strings):
                self.attributes_s[i] = NULL
            self.stringcount = strings

        if (numarrays > 0):
            self.attributes_na = <long **>PyMem_Malloc(sizeof(long **) *
                    numarrays)
            self.attributes_na_sizes = <long *>PyMem_Malloc(sizeof(long) *
                    numarrays)
            for i in range(numarrays):
                self.attributes_na[i] = NULL
                self.attributes_na_sizes[i] = 0
            self.numarraycount = numarrays

        self.sizeinbuf = 0

    def __dealloc__(self):
        cdef unsigned int i
        if self.attributes_s != NULL:
            for i in range(self.stringcount):
                if self.attributes_s[i] != NULL:
                    PyMem_Free(self.attributes_s[i])
            PyMem_Free(self.attributes_s)


        if self.attributes_na != NULL:
            for i in range(self.numarraycount):
                if self.attributes_na[i] != NULL:
                    PyMem_Free(self.attributes_na[i])
            PyMem_Free(self.attributes_na)

        if self.attributes_na_sizes != NULL:
            PyMem_Free(self.attributes_na_sizes)

        if self.attributes_l != NULL:
            PyMem_Free(self.attributes_l)

    @cython.boundscheck(False)
    @cython.wraparound(False)
    cdef int parseNumeric(self, const unsigned char[:] buf,
            const unsigned int maxlen, const int attrind):
        cdef unsigned int offinc
        cdef long longval

        if attrind < 0 or <unsigned int>attrind >= self.numcount:
            return -1

        offinc, longval = read_long(buf, maxlen)
        if offinc == 0:
            return -1

        self.attributes_l[attrind] = longval
        self.sizeinbuf += offinc

        return offinc

    cpdef long getNumeric(self, const int attrind):
        return self.attributes_l[<int>attrind]

    cpdef str getString(self, const int attrind):
        return str(self.attributes_s[<int>attrind])

    cdef unsigned int getRecordSizeInBuffer(self):
        return self.sizeinbuf

    cpdef vector[long] getNumericArray(self, const int attrind):
        cdef int i
        cdef vector[long] vec

        for i in range(self.attributes_na_sizes[attrind]):
            vec.push_back(self.attributes_na[<int>attrind][i])
        return vec

    @cython.wraparound(False)
    @cython.boundscheck(False)
    cdef unsigned int parseString(self, const unsigned char[:] buf,
            const unsigned int maxlen, const int attrind):

        cdef parsedString astr

        if attrind < 0 or <unsigned int>attrind >= self.stringcount:
            return 0


        astr = read_string(buf, maxlen, True)

        if astr.toskip == 0:
            return 0

        self.sizeinbuf += astr.toskip + astr.strlen
        self.attributes_s[attrind] = <char *>astr.start
        return astr.toskip + astr.strlen

    @cython.wraparound(False)
    @cython.boundscheck(False)
    cdef unsigned int parseNumericArray(self, const unsigned char[:] buf,
            const unsigned int maxlen, const int attrind):

        cdef parsedNumericArrayBlock block
        cdef unsigned int toskip, i

        if attrind < 0 or <unsigned int>attrind >= self.numarraycount:
            return 0

        toskip = 0
        while toskip < maxlen:
            block = read_numeric_array(buf[toskip:], maxlen - toskip)

            if block.blockcount == 0:
                toskip += block.totalsize
                break

            if self.attributes_na[attrind] == NULL:
                self.attributes_na[attrind] = block.values
                self.attributes_na_sizes[attrind] = block.blockcount
            else:
                # XXX This code path is untested due to generally not being
                # used at all in practice
                newsize = block.blockcount + self.attributes_na_sizes[attrind]
                newmem = <long *>PyMem_Realloc(self.attributes_na[attrind],
                        newsize * sizeof(long))
                for i in range(block.blockcount):
                    newmem[self.attributes_na_sizes[attrind] + i] = block.values[i]
                self.attributes_na_sizes[attrind] += block.blockcount
                self.attributes_na[attrind] = newmem
                PyMem_Free(block.values)


            toskip += block.totalsize

        self.sizeinbuf += toskip
        return toskip


    cpdef void resetRecord(self):
        cdef unsigned int i

        self.sizeinbuf = 0

        if self.attributes_s != NULL:
            for i in range(self.stringcount):
                if self.attributes_s[i] != NULL:
                    PyMem_Free(self.attributes_s[i])
                    self.attributes_s[i] = NULL

        if self.attributes_na != NULL:
            for i in range(self.numarraycount):
                if self.attributes_na[i] != NULL:
                    PyMem_Free(self.attributes_na[i])
                    self.attributes_na_sizes[i] = 0
                    self.attributes_na[i] = NULL


cdef class AvroReader:
    def __init__(self, filepath):
        self.filepath = filepath
        self.syncmarker = None
        self.fh = None
        self.bufrin = bytearray()
        self.nextblock = 0
        self.unzipped = None
        self.unzip_offset = 0
        self.currentrec = None
        self.schemajson = None

    def _readMore(self):
        try:
            inread = self.fh.read(1024 * 1024)
        except UnicodeDecodeError as e:
            print(e)
            return -1
        except KeyboardInterrupt:
            return -1

        if len(inread) > 0 and inread != '':
            self.bufrin += inread
            return 1
        return 0

    cpdef void _readAvroFileHeader(self):
        cdef unsigned int offset, fullsize, offinc
        cdef int i
        cdef long array_size, keylen, vallen
        cdef parsedString mapkey, schemabytes

        if len(self.bufrin) < 32:
            if self._readMore() < 0:
                sys.exit(1)

        if len(self.bufrin) < 32:
            return

        offset = 4 + self.nextblock     # skip past 'Obj\x01'
        fullsize = len(self.bufrin)
        offinc, array_size = read_long(self.bufrin[offset:], fullsize - offset)
        if array_size is None:
            return
        offset += offinc

        for i in range(0, array_size):
            mapkey = read_string(self.bufrin[offset:], fullsize - offset)
            if mapkey.toskip == 0:
                return
            offset += (mapkey.toskip + mapkey.strlen)

            if mapkey.start.decode('ascii') == 'avro.schema':
                schemabytes = read_string(self.bufrin[offset:],
                        fullsize-offset)
                if schemabytes.toskip == 0:
                    PyMem_Free(mapkey.start)
                    return

                self.schemajson = json.loads(schemabytes.start)
                PyMem_Free(schemabytes.start)
                offset += (schemabytes.toskip + schemabytes.strlen)
            else:
                offinc, vallen = read_long(self.bufrin[offset:], fullsize - offset)
                if vallen is None:
                    PyMem_Free(mapkey.start)
                    return
                offset += (offinc + vallen)
            PyMem_Free(mapkey.start)

        # skip past trailing zero size array
        assert(self.bufrin[offset] == 0)
        offset += 1

        if fullsize - offset < 16:
            return

        self.syncmarker = self.bufrin[offset: offset+16]
        self.nextblock = offset + 16;

    def start(self):
        if self.fh is not None:
            return

        # Try 'rb' mode if pywandio supports it, else fallback to 'r'
        # and hope that we're not reading a file off local disk (that
        # pywandio will try to "decode" into utf-8)
        #
        # Future versions of pywandio may allow us to override the
        # decoding method, in which case we can rework this code to be
        # less clunky.
        mode = 'rb'
        saved = None
        while mode != 'fail':
            try:
                self.fh = wandio.open(self.filepath, mode=mode)
            except ValueError as e:
                if mode == 'rb':
                    mode = 'r'
                else:
                    mode = 'fail'
                    raise
            except Exception:
                raise

            if self.fh is not None:
                break


        if self.syncmarker is None:
            self._readAvroFileHeader()

    def close(self):
        self.fh.close()

    cdef int _parseNextRecord(self, const unsigned char[:] buf,
			const unsigned int maxlen):
        return 0

    cdef AvroRecord _getNextRecord(self):
        if self.unzipped is None:
            return None

        if self.unzip_offset >= len(self.unzipped):
            return None

        if self._parseNextRecord(self.unzipped[self.unzip_offset:],
                len(self.unzipped) - self.unzip_offset) == 0:
            return None

        self.unzip_offset += self.currentrec.getRecordSizeInBuffer()
        return self.currentrec

    @cython.boundscheck(False)
    @cython.wraparound(False)
    cpdef void perAvroRecord(self, func, userarg=None):
        cdef unsigned int offset, fullsize
        cdef unsigned int offinc
        cdef long blockcnt, blocksize
        cdef AvroRecord nextrec

        while self.syncmarker is None:
            self._readAvroFileHeader()

        while 1:
            offset = self.nextblock
            fullsize = len(self.bufrin) - self.nextblock

            offinc, blockcnt = read_long(self.bufrin[offset:],
                    fullsize - offset)
            if offinc == 0:
                if self._readMore() == 0:
                    break
                continue
            offset += offinc
            offinc, blocksize = read_long(self.bufrin[offset:],
                    fullsize - offset)
            if offinc == 0:
                if self._readMore() == 0:
                    break
                continue

            offset += offinc

            content = self.bufrin[offset: offset + blocksize]
            if len(content) < blocksize or \
                    len(self.bufrin[offset + blocksize:]) < 16:
                if self._readMore() == 0:
                    break
                continue

            try:
                self.unzipped = zlib.decompress(content, -15)
                self.unzip_offset = 0
            except zlib.error:
                return

            nextrec = self._getNextRecord()
            while nextrec is not None:
                func(nextrec, userarg)
                nextrec = self._getNextRecord()

            offset += blocksize

            #assert(self.bufrin[offset: offset+16] == self.syncmarker)

            self.nextblock = offset + 16

            if self.nextblock >= len(self.bufrin):
                if self._readMore() == 0:
                    break

            self.bufrin = self.bufrin[self.nextblock:]
            self.nextblock = 0




# vim: set sw=4 tabstop=4 softtabstop=4 expandtab :
