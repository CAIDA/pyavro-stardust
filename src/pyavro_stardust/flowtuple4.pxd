import cython
from pyavro_stardust.baseavro cimport AvroRecord, AvroReader

cpdef enum Flowtuple4AttributeNum:
    ATTR_FT4_TIMESTAMP = 0
    ATTR_FT4_SRC_IP = 1
    ATTR_FT4_DST_NET = 2
    ATTR_FT4_DST_PORT = 3
    ATTR_FT4_PROTOCOL = 4
    ATTR_FT4_PKT_COUNT = 5
    ATTR_FT4_UNIQ_DST_IPS = 6
    ATTR_FT4_UNIQ_PKT_SIZES = 7
    ATTR_FT4_UNIQ_TTLS = 8
    ATTR_FT4_UNIQ_SRC_PORTS = 9
    ATTR_FT4_UNIQ_TCP_FLAGS = 10
    ATTR_FT4_FIRST_SYN_LEN = 11
    ATTR_FT4_FIRST_TCP_RWIN = 12
    ATTR_FT4_ASN = 13

cpdef enum Flowtuple4AttributeStr:
    ATTR_FT4_MAXMIND_CONTINENT = 0
    ATTR_FT4_MAXMIND_COUNTRY = 1
    ATTR_FT4_NETACQ_CONTINENT = 2
    ATTR_FT4_NETACQ_COUNTRY = 3
    ATTR_FT4_LAST_STRING = 4

cpdef enum Flowtuple4AttributeNumArray:
    ATTR_FT4_COMMON_PKT_SIZES = 0
    ATTR_FT4_COMMON_PKT_SIZE_FREQS = 1
    ATTR_FT4_COMMON_TTLS = 2
    ATTR_FT4_COMMON_TTL_FREQS = 3
    ATTR_FT4_COMMON_SRC_PORTS = 4
    ATTR_FT4_COMMON_SRC_PORT_FREQS = 5
    ATTR_FT4_COMMON_TCP_FLAGS = 6
    ATTR_FT4_COMMON_TCP_FLAG_FREQS = 7
    ATTR_FT4_LAST_NUM_ARRAY = 8

cdef struct CommonValue:
    long value
    long freq

cdef class AvroFlowtuple4(AvroRecord):
    cpdef dict asDict(self, int needarrays)

cdef class AvroFlowtuple4Reader(AvroReader):
    cdef int _parseNextRecord(self, const unsigned char[:] buf,
            const unsigned int maxlen)

# vim: set sw=4 tabstop=4 softtabstop=4 expandtab :
