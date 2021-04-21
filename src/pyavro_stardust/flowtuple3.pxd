import cython
from pyavro_stardust.baseavro cimport AvroRecord, AvroReader

cpdef enum Flowtuple3AttributeNum:
    ATTR_FT3_TIMESTAMP = 0
    ATTR_FT3_SRC_IP = 1
    ATTR_FT3_DST_IP = 2
    ATTR_FT3_SRC_PORT = 3
    ATTR_FT3_DST_PORT = 4
    ATTR_FT3_PROTOCOL = 5
    ATTR_FT3_TTL = 6
    ATTR_FT3_TCP_FLAGS = 7
    ATTR_FT3_IP_LEN = 8
    ATTR_FT3_SYN_LEN = 9
    ATTR_FT3_SYNWIN_LEN = 10
    ATTR_FT3_PKT_COUNT = 11
    ATTR_FT3_ISSPOOFED = 12
    ATTR_FT3_ISMASSCAN = 13
    ATTR_FT3_ASN = 14

cpdef enum Flowtuple3AttributeStr:
    ATTR_FT3_MAXMIND_CONTINENT = 0
    ATTR_FT3_MAXMIND_COUNTRY = 1
    ATTR_FT3_NETACQ_CONTINENT = 2
    ATTR_FT3_NETACQ_COUNTRY = 3


cdef class AvroFlowtuple3(AvroRecord):
    cpdef dict asDict(self)

cdef class AvroFlowtuple3Reader(AvroReader):
    cdef int _parseNextRecord(self, const unsigned char[:] buf,
            const unsigned int maxlen)


# vim: set sw=4 tabstop=4 softtabstop=4 expandtab :
