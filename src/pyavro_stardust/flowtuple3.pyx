# cython: language_level=3
cimport cython
from pyavro_stardust.baseavro cimport AvroRecord, read_long, read_string, \
        AvroReader

@cython.final
cdef class AvroFlowtuple3(AvroRecord):

    def __init__(self):
        super().__init__(ATTR_FT3_ASN + 1, ATTR_FT3_NETACQ_COUNTRY + 1)

    def __str__(self):
        return "%u %08x %08x %u %u %u %u %u %u %s %s %u" % \
            (self.attributes_l[<int>ATTR_FT3_TIMESTAMP], \
             self.attributes_l[<int>ATTR_FT3_SRC_IP], \
             self.attributes_l[<int>ATTR_FT3_DST_IP], \
             self.attributes_l[<int>ATTR_FT3_SRC_PORT], \
             self.attributes_l[<int>ATTR_FT3_DST_PORT], \
             self.attributes_l[<int>ATTR_FT3_PROTOCOL], \
             self.attributes_l[<int>ATTR_FT3_TTL], \
             self.attributes_l[<int>ATTR_FT3_TCP_FLAGS], \
             self.attributes_l[<int>ATTR_FT3_IP_LEN], \
             self.attributes_s[<int>ATTR_FT3_NETACQ_CONTINENT].decode('utf-8'), \
             self.attributes_s[<int>ATTR_FT3_NETACQ_COUNTRY].decode('utf-8'), \
             self.attributes_l[<int>ATTR_FT3_ASN])

    cpdef dict asDict(self):
        return {
            "timestamp": self.attributes_l[<int>ATTR_FT3_TIMESTAMP],
            "src_ip": self.attributes_l[<int>ATTR_FT3_SRC_IP],
            "dst_ip": self.attributes_l[<int>ATTR_FT3_DST_IP],
            "src_port": self.attributes_l[<int>ATTR_FT3_SRC_PORT],
            "dst_port": self.attributes_l[<int>ATTR_FT3_DST_PORT],
            "protocol": self.attributes_l[<int>ATTR_FT3_PROTOCOL],
            "ttl": self.attributes_l[<int>ATTR_FT3_TTL],
            "tcpflags": self.attributes_l[<int>ATTR_FT3_TCP_FLAGS],
            "ip_len": self.attributes_l[<int>ATTR_FT3_IP_LEN],
            "packets": self.attributes_l[<int>ATTR_FT3_PKT_COUNT],
            "tcp_synlen": self.attributes_l[<int>ATTR_FT3_SYN_LEN],
            "tcp_synwinlen": self.attributes_l[<int>ATTR_FT3_SYNWIN_LEN],
            "is_spoofed": self.attributes_l[<int>ATTR_FT3_ISSPOOFED],
            "is_masscan": self.attributes_l[<int>ATTR_FT3_ISMASSCAN],
            "asn": self.attributes_l[<int>ATTR_FT3_ASN],
            "netacq_continent": self.attributes_s[<int>ATTR_FT3_NETACQ_CONTINENT],
            "netacq_country": self.attributes_s[<int>ATTR_FT3_NETACQ_COUNTRY],
            "maxmind_country": self.attributes_s[<int>ATTR_FT3_MAXMIND_COUNTRY],
            "maxmind_continent": self.attributes_s[<int>ATTR_FT3_MAXMIND_CONTINENT]
        }

@cython.final
cdef class AvroFlowtuple3Reader(AvroReader):

    def __init__(self, filepath):
        super().__init__(filepath)
        self.currentrec = AvroFlowtuple3()

    cdef int _parseNextRecord(self, const unsigned char[:] buf,
            const int maxlen):

        cdef int offset, offinc
        cdef Flowtuple3AttributeNum i
        cdef Flowtuple3AttributeStr j

        if maxlen == 0:
            return 0
        offset = 0

        self.currentrec.resetRecord()

        # Process each field in turn -- order is critical, must match
        # field order in avro record!
        for i in range(0, ATTR_FT3_ISMASSCAN + 1):
            offinc = self.currentrec.parseNumeric(buf[offset:],
                    maxlen - offset, i)
            if offinc <= 0:
                return 0
            offset += offinc

        for j in range(0, ATTR_FT3_NETACQ_COUNTRY + 1):
            offinc = self.currentrec.parseString(buf[offset:],
                    maxlen - offset, j)
            if offinc <= 0:
                return 0
            offset += offinc

        offinc = self.currentrec.parseNumeric(buf[offset:], maxlen - offset,
                ATTR_FT3_ASN)
        if offinc <= 0:
            return 0
        offset += offinc

        return 1


# vim: set sw=4 tabstop=4 softtabstop=4 expandtab :
