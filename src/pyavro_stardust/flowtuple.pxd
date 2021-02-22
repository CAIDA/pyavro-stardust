import cython

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


@cython.final
cdef class AvroFlowtuple:

    cdef unsigned int sizeinbuf
    cdef long attributes_l[16]
    cdef char *attributes_s[4]

    cdef int parseNumeric(self, const unsigned char[:] buf, const int maxlen,
                int attrind)
    cpdef long getNumeric(self, int attrind)
    cpdef str getString(self, int attrind)
    cpdef unsigned int getFlowtupleSizeInBuffer(self)
    cpdef dict asDict(self)
    cdef int parseString(self, const unsigned char[:] buf, const int maxlen,
                int attrind)
    cpdef void releaseStrings(self)

@cython.final
cdef class AvroFlowtupleReader:

    cdef unsigned int nextblock
    cdef unsigned int unzip_offset
    cdef fh
    cdef str filepath
    cdef bytearray syncmarker
    cdef bytearray bufrin
    cdef bytes unzipped

    cpdef void _readAvroFileHeader(self)
    cdef AvroFlowtuple _parseFlowtupleAvro(self, const unsigned char[:] buf,
            const int maxlen)
    cdef AvroFlowtuple _getNextFlowtuple(self)


# vim: set sw=4 tabstop=4 softtabstop=4 expandtab :
