# cython: language_level=3
from libc.string cimport memcpy
from cpython.mem cimport PyMem_Malloc, PyMem_Free
import zlib, wandio
cimport cython

cdef (int, long) read_long(const unsigned char[:] buf, const int maxlen):
    cdef int longlen = 0
    cdef int shift
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

cdef parsedString read_string(const unsigned char[:] buf, const int maxlen):
    cdef int skip, strlen
    cdef parsedString s

    skip,strlen = read_long(buf, maxlen)
    if skip == 0:
        s.toskip = 0
        s.strlen = 0
        s.start = NULL
        return s

    s.toskip = skip
    s.strlen = strlen
    s.start = <unsigned char *>&(buf[skip])
    return s


cdef class AvroRecord:

    def __cinit__(self):
        self.attributes_l = NULL
        self.attributes_s = NULL

    def __init__(self, numeric, strings):
        self.attributes_l = <long *>PyMem_Malloc(sizeof(long) * numeric)
        self.attributes_s = <char **>PyMem_Malloc(sizeof(char *) * strings)

        for i in range(numeric):
            self.attributes_l[i] = 0
        for i in range(strings):
            self.attributes_s[i] = NULL
        self.sizeinbuf = 0
        self.stringcount = strings
        self.numcount = numeric

    def __dealloc__(self):
        if self.attributes_s != NULL:
            for i in range(self.stringcount):
                if self.attributes_s[i] != NULL:
                    PyMem_Free(self.attributes_s[i])
            PyMem_Free(self.attributes_s)

        if self.attributes_l != NULL:
            PyMem_Free(self.attributes_l)

    cdef int parseNumeric(self, const unsigned char[:] buf, const int maxlen,
            int attrind):
        cdef int offinc
        cdef long longval

        offinc, longval = read_long(buf, maxlen)
        if offinc == 0:
            return -1

        self.attributes_l[attrind] = longval
        self.sizeinbuf += offinc

        return offinc

    cpdef long getNumeric(self, int attrind):
        return self.attributes_l[<int>attrind]

    cpdef str getString(self, int attrind):
        return str(self.attributes_s[<int>attrind])

    cpdef unsigned int getRecordSizeInBuffer(self):
        return self.sizeinbuf

    cdef int parseString(self, const unsigned char[:] buf, const int maxlen,
            int attrind):

        cdef parsedString astr

        astr = read_string(buf, maxlen)

        if astr.toskip == 0:
            return 0

        self.sizeinbuf += astr.toskip + astr.strlen
        self.attributes_s[attrind] = <char *>PyMem_Malloc(sizeof(char) * astr.strlen + 1)

        memcpy(self.attributes_s[attrind], astr.start, astr.strlen)
        self.attributes_s[attrind][astr.strlen] = b'\x00'

        return astr.toskip + astr.strlen

    cpdef void resetRecord(self):
        self.sizeinbuf = 0

        if self.attributes_s == NULL:
            return

        for i in range(self.stringcount):
            if self.attributes_s[i] != NULL:
                PyMem_Free(self.attributes_s[i])
                self.attributes_s[i] = NULL



# vim: set sw=4 tabstop=4 softtabstop=4 expandtab :
