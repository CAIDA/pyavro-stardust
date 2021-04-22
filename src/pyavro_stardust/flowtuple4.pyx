# This software is Copyright (C) 2021 The Regents of the University of
# California. All Rights Reserved. Permission to copy, modify, and distribute
# this software and its documentation for educational, research and non-profit
# purposes, without fee, and without a written agreement is hereby granted,
# provided that the above copyright notice, this paragraph and the following
# three paragraphs appear in all copies. Permission to make commercial use of
# this software may be obtained by contacting:
#
# Office of Innovation and Commercialization
# 9500 Gilman Drive, Mail Code 0910
# University of California
# La Jolla, CA 92093-0910
# (858) 534-5815
# invent@ucsd.edu
#
# This software program and documentation are copyrighted by The Regents of the
# University of California. The software program and documentation are supplied
# "as is", without any accompanying services from The Regents. The Regents does
# not warrant that the operation of the program will be uninterrupted or
# error-free. The end-user understands that the program was developed for
# research purposes and is advised not to rely exclusively on the program for
# any reason.
#
# IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING
# LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION,
# EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE. THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED
# HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO
# OBLIGATIONS TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
# MODIFICATIONS.

# cython: language_level=3
cimport cython
from pyavro_stardust.baseavro cimport AvroRecord, AvroReader
from libcpp.vector cimport vector
from cpython cimport array

@cython.final
cdef class AvroFlowtuple4(AvroRecord):
    def __init__(self):
        super().__init__(ATTR_FT4_ASN + 1, ATTR_FT4_LAST_STRING,
                ATTR_FT4_LAST_NUM_ARRAY)

    def __str__(self):
        return "%u %08x %08x %u %u %u %lu" % \
                (self.attributes_l[<int>ATTR_FT4_TIMESTAMP], \
                 self.attributes_l[<int>ATTR_FT4_SRC_IP], \
                 self.attributes_l[<int>ATTR_FT4_DST_NET], \
                 self.attributes_l[<int>ATTR_FT4_DST_PORT], \
                 self.attributes_l[<int>ATTR_FT4_PROTOCOL], \
                 self.attributes_l[<int>ATTR_FT4_PKT_COUNT], \
                 self.attributes_l[<int>ATTR_FT4_ASN])

    cpdef dict asDict(self, int needarrays):
        cdef vector[long] ttls, ttl_freqs
        cdef vector[long] src_ports, port_freqs
        cdef vector[long] pkt_sizes, size_freqs
        cdef vector[long] flags, flag_freqs
        cdef unsigned int i
        cdef vector[CommonValue] comm_ttls
        cdef vector[CommonValue] comm_ports
        cdef vector[CommonValue] comm_sizes
        cdef vector[CommonValue] comm_flags
        cdef CommonValue cv

        asdict = {
            "timestamp": self.attributes_l[<int>ATTR_FT4_TIMESTAMP],
            "src_ip": self.attributes_l[<int>ATTR_FT4_SRC_IP],
            "dst_net": self.attributes_l[<int>ATTR_FT4_DST_NET],
            "dst_port": self.attributes_l[<int>ATTR_FT4_DST_PORT],
            "protocol": self.attributes_l[<int>ATTR_FT4_PROTOCOL],
            "packets": self.attributes_l[<int>ATTR_FT4_PKT_COUNT],
            "uniq_dst_ips": self.attributes_l[<int>ATTR_FT4_UNIQ_DST_IPS],
            "uniq_pkt_sizes": self.attributes_l[<int>ATTR_FT4_UNIQ_PKT_SIZES],
            "uniq_ttls": self.attributes_l[<int>ATTR_FT4_UNIQ_TTLS],
            "uniq_src_ports": self.attributes_l[<int>ATTR_FT4_UNIQ_SRC_PORTS],
            "uniq_tcp_flags": self.attributes_l[<int>ATTR_FT4_UNIQ_TCP_FLAGS],
            "first_syn_len": self.attributes_l[<int>ATTR_FT4_FIRST_SYN_LEN],
            "first_tcp_rwin": self.attributes_l[<int>ATTR_FT4_FIRST_TCP_RWIN],
            "asn": self.attributes_l[<int>ATTR_FT4_ASN],
            "netacq_continent": self.attributes_s[<int>ATTR_FT4_NETACQ_CONTINENT],
            "netacq_country": self.attributes_s[<int>ATTR_FT4_NETACQ_COUNTRY],
            "maxmind_continent": self.attributes_s[<int>ATTR_FT4_MAXMIND_CONTINENT],
            "maxmind_country": self.attributes_s[<int>ATTR_FT4_MAXMIND_COUNTRY]
        }

        if needarrays:
            # XXX this feels like it could be faster, but not sure how
            # to improve this
            ttls = self.getNumericArray(<int>ATTR_FT4_COMMON_TTLS)
            ttl_freqs = self.getNumericArray(<int>ATTR_FT4_COMMON_TTL_FREQS)
            for i in range(ttls.size()):
                cv.value = ttls[i]
                cv.freq = ttl_freqs[i]
                comm_ttls.push_back(cv)
            asdict['common_ttls'] = comm_ttls

            src_ports = self.getNumericArray(<int>ATTR_FT4_COMMON_SRC_PORTS)
            port_freqs = self.getNumericArray(<int>ATTR_FT4_COMMON_SRC_PORT_FREQS)
            for i in range(src_ports.size()):
                cv.value = src_ports[i]
                cv.freq = port_freqs[i]
                comm_ports.push_back(cv)
            asdict['common_src_ports'] = comm_ports

            pkt_sizes = self.getNumericArray(<int>ATTR_FT4_COMMON_PKT_SIZES)
            size_freqs = self.getNumericArray(<int>ATTR_FT4_COMMON_PKT_SIZE_FREQS)
            for i in range(pkt_sizes.size()):
                cv.value = pkt_sizes[i]
                cv.freq = size_freqs[i]
                comm_sizes.push_back(cv)
            asdict['common_pkt_sizes'] = comm_sizes

            flags = self.getNumericArray(<int>ATTR_FT4_COMMON_TCP_FLAGS)
            flag_freqs = self.getNumericArray(<int>ATTR_FT4_COMMON_TCP_FLAG_FREQS)
            for i in range(flags.size()):
                cv.value = flags[i]
                cv.freq = flag_freqs[i]
                comm_flags.push_back(cv)
            asdict['common_tcp_flags'] = comm_flags

        return asdict

@cython.final
cdef class AvroFlowtuple4Reader(AvroReader):
    def __init__(self, filepath):
        super().__init__(filepath)
        self.currentrec = AvroFlowtuple4()

    cdef int _parseNextRecord(self, const unsigned char[:] buf,
            const unsigned int maxlen):
        cdef unsigned int offset, offinc
        cdef Flowtuple4AttributeNum i
        cdef Flowtuple4AttributeStr j
        cdef Flowtuple4AttributeNumArray k

        if maxlen == 0:
            return 0
        offset = 0

        self.currentrec.resetRecord()

        for i in range(0, ATTR_FT4_FIRST_TCP_RWIN + 1):
            offinc = self.currentrec.parseNumeric(buf[offset:],
                    maxlen - offset, i)
            if offinc <= 0:
                return 0
            offset += offinc

        for k in range(0, ATTR_FT4_LAST_NUM_ARRAY):
            offinc = self.currentrec.parseNumericArray(buf[offset:],
                    maxlen - offset, k)
            if offinc <= 0:
                return 0
            offset += offinc

        for j in range(0, ATTR_FT4_LAST_STRING):
            offinc = self.currentrec.parseString(buf[offset:], maxlen - offset,
                    j)
            if offinc <= 0:
                return 0
            offset += offinc

        offinc = self.currentrec.parseNumeric(buf[offset:], maxlen - offset,
                ATTR_FT4_ASN)
        if offinc <= 0:
            return 0
        offset += offinc
        return 1



# vim: set sw=4 tabstop=4 softtabstop=4 expandtab :

