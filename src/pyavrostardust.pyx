# cython: language_level=3
from libc.string cimport memcpy
from cpython.mem cimport PyMem_Malloc, PyMem_Free
import zlib, wandio

cdef struct parsedString:
    int toskip
    int strlen
    unsigned char *start

cpdef enum FlowtupleAttributeNum:
    ATTR_FT_TIMESTAMP = 0
    ATTR_FT_SRC_IP = 1
    ATTR_FT_DST_IP = 2
    ATTR_FT_SRC_PORT = 3
    ATTR_FT_DST_PORT = 4
    ATTR_FT_PROTOCOL = 5
    ATTR_FT_TTL = 6
    ATTR_FT_TCP_FLAGS = 7
    ATTR_FT_IP_LEN = 8
    ATTR_FT_SYN_LEN = 9
    ATTR_FT_SYNWIN_LEN = 10
    ATTR_FT_PKT_COUNT = 11
    ATTR_FT_ISSPOOFED = 12
    ATTR_FT_ISMASSCAN = 13
    ATTR_FT_ASN = 14

cpdef enum FlowtupleAttributeStr:
    ATTR_FT_MAXMIND_CONTINENT = 0
    ATTR_FT_MAXMIND_COUNTRY = 1
    ATTR_FT_NETACQ_CONTINENT = 2
    ATTR_FT_NETACQ_COUNTRY = 3

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


cdef class AvroFlowtuple:

    cdef unsigned int sizeinbuf
    cdef long attributes_l[16]
    cdef char *attributes_s[4]

    def __init__(self):
        for i in range(16):
            self.attributes_l[i] = 0

        for i in range(4):
            self.attributes_s[i] = NULL

        self.sizeinbuf = 0

    def __dealloc__(self):
        for i in range(4):
            if self.attributes_s[i] != NULL:
                PyMem_Free(self.attributes_s[i])


    def __str__(self):
        return "%u %08x %08x %u %u %u %u %u %u %s %s %u" % \
            (self.attributes_l[<int>ATTR_FT_TIMESTAMP], \
             self.attributes_l[<int>ATTR_FT_SRC_IP], \
             self.attributes_l[<int>ATTR_FT_DST_IP], \
             self.attributes_l[<int>ATTR_FT_SRC_PORT], \
             self.attributes_l[<int>ATTR_FT_DST_PORT], \
             self.attributes_l[<int>ATTR_FT_PROTOCOL], \
             self.attributes_l[<int>ATTR_FT_TTL], \
             self.attributes_l[<int>ATTR_FT_TCP_FLAGS], \
             self.attributes_l[<int>ATTR_FT_IP_LEN], \
             self.attributes_s[<int>ATTR_FT_NETACQ_CONTINENT].decode('utf-8'), \
             self.attributes_s[<int>ATTR_FT_NETACQ_COUNTRY].decode('utf-8'), \
             self.attributes_l[<int>ATTR_FT_ASN])

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
        return self.attributes_l[attrind]

    cpdef str getString(self, int attrind):
        return str(self.attributes_s[attrind])

    cpdef unsigned int getFlowtupleSizeInBuffer(self):
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

    cpdef void releaseStrings(self):
        for i in range(4):
            if self.attributes_s[i] != NULL:
                PyMem_Free(self.attributes_s[i])
                self.attributes_s[i] = NULL


cdef class AvroFlowtupleReader:

    cdef unsigned int nextblock
    cdef unsigned int unzip_offset
    cdef fh
    cdef str filepath
    cdef bytearray syncmarker
    cdef bytearray bufrin
    cdef bytes unzipped

    def __init__(self, filepath):
        self.filepath = filepath
        self.syncmarker = None
        self.fh = None
        self.bufrin = bytearray()
        self.nextblock = 0
        self.unzipped = None
        self.unzip_offset = 0

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

    cdef AvroFlowtuple _parseFlowtupleAvro(self, const unsigned char[:] buf,
            const int maxlen):

        cdef int offset, offinc
        cdef AvroFlowtuple ft
        cdef FlowtupleAttributeNum i
        cdef FlowtupleAttributeStr j

        if maxlen == 0:
            return None
        offset = 0
        ft = AvroFlowtuple()

        # Process each field in turn -- order is critical, must match
        # field order in avro record!
        for i in range(0, ATTR_FT_ISMASSCAN + 1):
            offinc = ft.parseNumeric(buf[offset:], maxlen - offset, i)
            if offinc <= 0:
                return None
            offset += offinc

        for j in range(0, ATTR_FT_NETACQ_COUNTRY + 1):
            offinc = ft.parseString(buf[offset:], maxlen - offset, j)
            if offinc <= 0:
                return None
            offset += offinc

        offinc = ft.parseNumeric(buf[offset:], maxlen - offset, ATTR_FT_ASN)
        if offinc <= 0:
            return None
        offset += offinc

        return ft


    cdef AvroFlowtuple _getNextFlowtuple(self):
        if self.unzipped is None:
            return None

        if self.unzip_offset >= len(self.unzipped):
            return None

        ft = self._parseFlowtupleAvro(self.unzipped[self.unzip_offset:],
                len(self.unzipped) - self.unzip_offset)
        if ft is not None:
            self.unzip_offset += ft.getFlowtupleSizeInBuffer()
        return ft


    def perFlowtuple(self, func):
        cdef unsigned int offset, fullsize
        cdef int offinc
        cdef long blockcnt, blocksize

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

            ft = self._getNextFlowtuple()
            while ft is not None:

                func(ft)
                ft.releaseStrings()
                ft = self._getNextFlowtuple()

            offset += blocksize

            assert(self.bufrin[offset: offset+16] == self.syncmarker)

            self.nextblock = offset + 16

            if self.nextblock >= len(self.bufrin):
                if self._readMore() == 0:
                    break

            self.bufrin = self.bufrin[self.nextblock:]
            self.nextblock = 0

# vim: set sw=4 tabstop=4 softtabstop=4 expandtab :
