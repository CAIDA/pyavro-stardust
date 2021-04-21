cimport cython
from pyavro_stardust.baseavro cimport AvroRecord, AvroReader, parsedString

cpdef enum RsdosAttribute:
    ATTR_RSDOS_TIMESTAMP = 0
    ATTR_RSDOS_PACKET_LEN = 1
    ATTR_RSDOS_TARGET_IP = 2
    ATTR_RSDOS_TARGET_PROTOCOL = 3
    ATTR_RSDOS_ATTACKER_IP_CNT = 4
    ATTR_RSDOS_ATTACK_PORT_CNT = 5
    ATTR_RSDOS_TARGET_PORT_CNT = 6
    ATTR_RSDOS_PACKET_CNT = 7
    ATTR_RSDOS_ICMP_MISMATCHES = 8
    ATTR_RSDOS_BYTE_CNT = 9
    ATTR_RSDOS_MAX_PPM_INTERVAL = 10
    ATTR_RSDOS_START_TIME_SEC = 11
    ATTR_RSDOS_START_TIME_USEC = 12
    ATTR_RSDOS_LATEST_TIME_SEC = 13
    ATTR_RSDOS_LATEST_TIME_USEC = 14
    ATTR_RSDOS_LAST_ATTRIBUTE = 15

cdef class AvroRsdos(AvroRecord):

    cdef unsigned char *packetcontent
    cdef public unsigned int pktcontentlen

    cpdef dict asDict(self)
    cpdef void resetRecord(self)
    cpdef bytes getRsdosPacketString(self)
    cpdef int setRsdosPacketString(self, const unsigned char[:] buf,
            const unsigned int maxlen)

cdef class AvroRsdosReader(AvroReader):
    cdef int _parseNextRecord(self, const unsigned char[:] buf,
            const unsigned int maxlen)


# vim: set sw=4 tabstop=4 softtabstop=4 expandtab :
