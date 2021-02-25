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

    def _readMore(self):
        inread = self.fh.read(1024 * 1024)
        if len(inread) > 0 and inread != '':
            self.bufrin += inread
            return 1
        return 0

    cpdef void _readAvroFileHeader(self):
        cdef unsigned int offset, fullsize
        cdef int offinc, i
        cdef long array_size, keylen, vallen

        if len(self.bufrin) < 32:
            self._readMore()

        if len(self.bufrin) < 32:
            return

        offset = 4 + self.nextblock     # skip past 'Obj\x01'
        fullsize = len(self.bufrin)
        offinc, array_size = read_long(self.bufrin[offset:], fullsize - offset)
        if array_size is None:
            return
        offset += offinc

        for i in range(0, array_size):
            offinc, keylen = read_long(self.bufrin[offset:], fullsize - offset)
            if keylen is None:
                return
            offset += (offinc + keylen)

            offinc, vallen = read_long(self.bufrin[offset:], fullsize - offset)
            if vallen is None:
                return
            offset += (offinc + vallen)

        # skip past trailing zero size array
        assert(self.bufrin[offset] == 0)
        offset += 1

        if fullsize - offset < 16:
            return

        self.syncmarker = bytearray(self.bufrin[offset: offset+16])
        self.nextblock = offset + 16;

    def start(self):
        if self.fh is not None:
            return
        try:
            self.fh = wandio.open(self.filepath)
        except:
            raise

        if self.syncmarker is None:
            self._readAvroFileHeader()

    def close(self):
        self.fh.close()

    cdef int _parseNextRecord(self, const unsigned char[:] buf,
			const int maxlen):
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

    def perAvroRecord(self, func, userarg=None):
        cdef unsigned int offset, fullsize
        cdef int offinc
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

            assert(self.bufrin[offset: offset+16] == self.syncmarker)

            self.nextblock = offset + 16

            if self.nextblock >= len(self.bufrin):
                if self._readMore() == 0:
                    break

            self.bufrin = self.bufrin[self.nextblock:]
            self.nextblock = 0




# vim: set sw=4 tabstop=4 softtabstop=4 expandtab :
