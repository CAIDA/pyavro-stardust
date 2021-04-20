
# cython: language_level=3
cimport cython
from pyavro_stardust.baseavro cimport AvroRecord, read_long, read_string, \
        AvroReader, parsedString

@cython.final
cdef class AvroRsdos(AvroRecord):
    def __init__(self):
        super().__init__(ATTR_RSDOS_LAST_ATTRIBUTE, 0, 0)
        self.pktcontentlen = 0
        self.packetcontent = NULL

    def __str__(self):
        return "%u %u.%06u %u.%06u %08x %u %u %u %u %u %u %u %u %u" % \
                (self.attributes_l[<int>ATTR_RSDOS_TIMESTAMP], \
                 self.attributes_l[<int>ATTR_RSDOS_START_TIME_SEC],
                 self.attributes_l[<int>ATTR_RSDOS_START_TIME_USEC],
                 self.attributes_l[<int>ATTR_RSDOS_LATEST_TIME_SEC],
                 self.attributes_l[<int>ATTR_RSDOS_LATEST_TIME_USEC],
                 self.attributes_l[<int>ATTR_RSDOS_TARGET_IP],
                 self.attributes_l[<int>ATTR_RSDOS_TARGET_PROTOCOL],
                 self.attributes_l[<int>ATTR_RSDOS_PACKET_LEN],
                 self.attributes_l[<int>ATTR_RSDOS_ATTACKER_IP_CNT],
                 self.attributes_l[<int>ATTR_RSDOS_ATTACK_PORT_CNT],
                 self.attributes_l[<int>ATTR_RSDOS_TARGET_PORT_CNT],
                 self.attributes_l[<int>ATTR_RSDOS_PACKET_CNT],
                 self.attributes_l[<int>ATTR_RSDOS_BYTE_CNT],
                 self.attributes_l[<int>ATTR_RSDOS_MAX_PPM_INTERVAL],
                 self.pktcontentlen)

    cpdef dict asDict(self):
        if self.pktcontentlen == 0:
            initpkt = None
        else:
            initpkt = <bytes>self.packetcontent

        return {
            "timestamp": self.attributes_l[<int>ATTR_RSDOS_TIMESTAMP],
            "start_time_sec": self.attributes_l[<int>ATTR_RSDOS_START_TIME_SEC],
            "start_time_usec": self.attributes_l[<int>ATTR_RSDOS_START_TIME_USEC],
            "latest_time_sec": self.attributes_l[<int>ATTR_RSDOS_LATEST_TIME_SEC],
            "latest_time_usec": self.attributes_l[<int>ATTR_RSDOS_LATEST_TIME_USEC],
            "target_ip": self.attributes_l[<int>ATTR_RSDOS_TARGET_IP],
            "target_protocol": self.attributes_l[<int>ATTR_RSDOS_TARGET_PROTOCOL],
            "packet_len": self.attributes_l[<int>ATTR_RSDOS_PACKET_LEN],
            "attacker_count": self.attributes_l[<int>ATTR_RSDOS_ATTACKER_IP_CNT],
            "attack_port_count": self.attributes_l[<int>ATTR_RSDOS_ATTACK_PORT_CNT],
            "target_port_count": self.attributes_l[<int>ATTR_RSDOS_TARGET_PORT_CNT],
            "packet_count": self.attributes_l[<int>ATTR_RSDOS_PACKET_CNT],
            "byte_count": self.attributes_l[<int>ATTR_RSDOS_BYTE_CNT],
            "max_ppm_interval": self.attributes_l[<int>ATTR_RSDOS_MAX_PPM_INTERVAL],
            "icmp_mismatches": self.attributes_l[<int>ATTR_RSDOS_ICMP_MISMATCHES],
            "initial_packet": initpkt,
        }


    cpdef void resetRecord(self):
        self.pktcontentlen = 0
        super(AvroRsdos, self).resetRecord()

    cdef void setRsdosPacketString(self, parsedString astr):
        self.packetcontent = astr.start
        self.pktcontentlen = astr.strlen

    cpdef bytes getRsdosPacketString(self):
        return <bytes>self.packetcontent

@cython.final
cdef class AvroRsdosReader(AvroReader):

    def __init__(self, filepath):
        super().__init__(filepath)
        self.currentrec = AvroRsdos()

    cdef int _parseNextRecord(self,  const unsigned char[:] buf,
            const int maxlen):

        cdef int offset, offinc
        cdef RsdosAttribute i
        cdef parsedString astr

        if maxlen == 0:
            return 0
        offset = 0

        self.currentrec.resetRecord()

        for i in range(0, ATTR_RSDOS_LATEST_TIME_USEC + 1):
            offinc = self.currentrec.parseNumeric(buf[offset:],
                    maxlen - offset, i)
            if offinc <= 0:
                return 0
            offset += offinc

        astr = read_string(buf[offset:], maxlen - offset)
        if astr.toskip == 0:
            return 0

        self.currentrec.setRsdosPacketString(astr)
        self.currentrec.sizeinbuf += astr.toskip + astr.strlen
        return 1


# vim: set sw=4 tabstop=4 softtabstop=4 expandtab :
