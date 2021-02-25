import cython
from pyavro_stardust.baseavro cimport AvroRecord, AvroReader

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


cdef class AvroFlowtuple(AvroRecord):
    cpdef dict asDict(self)

cdef class AvroFlowtupleReader(AvroReader):
    cdef int _parseNextRecord(self, const unsigned char[:] buf,
            const int maxlen)


# vim: set sw=4 tabstop=4 softtabstop=4 expandtab :
