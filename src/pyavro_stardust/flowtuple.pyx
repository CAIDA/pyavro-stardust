# cython: language_level=3
import zlib, wandio
cimport cython
from pyavro_stardust.baseavro cimport AvroRecord, read_long, read_string

@cython.final
cdef class AvroFlowtuple(AvroRecord):

    def __init__(self):
        super().__init__(ATTR_FT_ASN + 1, ATTR_FT_NETACQ_COUNTRY + 1)

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

    cpdef dict asDict(self):
        return {
            "timestamp": self.attributes_l[<int>ATTR_FT_TIMESTAMP],
            "src_ip": self.attributes_l[<int>ATTR_FT_SRC_IP],
            "dst_ip": self.attributes_l[<int>ATTR_FT_DST_IP],
            "src_port": self.attributes_l[<int>ATTR_FT_SRC_PORT],
            "dst_port": self.attributes_l[<int>ATTR_FT_DST_PORT],
            "protocol": self.attributes_l[<int>ATTR_FT_PROTOCOL],
            "ttl": self.attributes_l[<int>ATTR_FT_TTL],
            "tcpflags": self.attributes_l[<int>ATTR_FT_TCP_FLAGS],
            "ip_len": self.attributes_l[<int>ATTR_FT_IP_LEN],
            "packets": self.attributes_l[<int>ATTR_FT_PKT_COUNT],
            "tcp_synlen": self.attributes_l[<int>ATTR_FT_SYN_LEN],
            "tcp_synwinlen": self.attributes_l[<int>ATTR_FT_SYNWIN_LEN],
            "is_spoofed": self.attributes_l[<int>ATTR_FT_ISSPOOFED],
            "is_masscan": self.attributes_l[<int>ATTR_FT_ISMASSCAN],
            "asn": self.attributes_l[<int>ATTR_FT_ASN],
            "netacq_continent": self.attributes_s[<int>ATTR_FT_NETACQ_CONTINENT],
            "netacq_country": self.attributes_s[<int>ATTR_FT_NETACQ_COUNTRY],
            "maxmind_country": self.attributes_s[<int>ATTR_FT_MAXMIND_COUNTRY],
            "maxmind_continent": self.attributes_s[<int>ATTR_FT_MAXMIND_CONTINENT]
        }

@cython.final
cdef class AvroFlowtupleReader:

    def __init__(self, filepath):
        self.filepath = filepath
        self.syncmarker = None
        self.fh = None
        self.bufrin = bytearray()
        self.nextblock = 0
        self.unzipped = None
        self.unzip_offset = 0
        self.avroft = AvroFlowtuple()

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

    cdef int _parseFlowtupleAvro(self, const unsigned char[:] buf,
            const int maxlen):

        cdef int offset, offinc
        cdef FlowtupleAttributeNum i
        cdef FlowtupleAttributeStr j

        if maxlen == 0:
            return 0
        offset = 0

        self.avroft.resetRecord()

        # Process each field in turn -- order is critical, must match
        # field order in avro record!
        for i in range(0, ATTR_FT_ISMASSCAN + 1):
            offinc = self.avroft.parseNumeric(buf[offset:], maxlen - offset, i)
            if offinc <= 0:
                return 0
            offset += offinc

        for j in range(0, ATTR_FT_NETACQ_COUNTRY + 1):
            offinc = self.avroft.parseString(buf[offset:], maxlen - offset, j)
            if offinc <= 0:
                return 0
            offset += offinc

        offinc = self.avroft.parseNumeric(buf[offset:], maxlen - offset, ATTR_FT_ASN)
        if offinc <= 0:
            return 0
        offset += offinc

        return 1

    cdef AvroFlowtuple _getNextFlowtuple(self):
        if self.unzipped is None:
            return None

        if self.unzip_offset >= len(self.unzipped):
            return None

        if self._parseFlowtupleAvro(self.unzipped[self.unzip_offset:],
                len(self.unzipped) - self.unzip_offset) == 0:
            return None

        self.unzip_offset += self.avroft.getRecordSizeInBuffer()
        return self.avroft


    def perFlowtuple(self, func, userarg=None):
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

                func(ft, userarg)
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
