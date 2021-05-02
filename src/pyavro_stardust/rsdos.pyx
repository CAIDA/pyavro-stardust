# cython: language_level=3

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

cimport cython
from cpython.mem cimport PyMem_Free
from pyavro_stardust.baseavro cimport AvroRecord, read_long, read_string, \
        AvroReader, parsedString

@cython.final
cdef class AvroRsdos(AvroRecord):
    def __init__(self):
        super().__init__(ATTR_RSDOS_LAST_ATTRIBUTE, 0, 0)
        self.pktcontentlen = 0
        self.packetcontent = NULL
        self.schemaversion = 1

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
                 self.getRsdosPacketSize())

    cpdef dict asDict(self):
        cdef dict result

        if self.getRsdosPacketSize() == 0:
            initpkt = None
        else:
            initpkt = self.getRsdosPacketString()

        result = {
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

        if self.schemaversion == 2:
            result['first_attack_port'] = self.attributes_l[<int>ATTR_RSDOS_FIRST_ATTACK_PORT]
            result['first_target_port'] = self.attributes_l[<int>ATTR_RSDOS_FIRST_TARGET_PORT]

        return result


    cpdef void resetRecord(self):
        self.pktcontentlen = 0
        if self.packetcontent != NULL:
            PyMem_Free(self.packetcontent)
        super(AvroRsdos, self).resetRecord()

    cpdef bytes getRsdosPacketString(self):
        cdef unsigned int tagheadersize

        tagheadersize = 0

        # Ideally, we would be able to pull the size out of libtrace or
        # libcorsaro, but for now we'll just have to hard-code the size here
        if self.schemaversion == 1:
            tagheadersize = 35 + (4 * 8)

        if self.pktcontentlen <= tagheadersize:
            return None

        return <bytes>self.packetcontent[tagheadersize:self.pktcontentlen]

    cpdef unsigned int getRsdosPacketSize(self):
        cdef unsigned int tagheadersize

        tagheadersize = 0

        # Ideally, we would be able to pull the size out of libtrace or
        # libcorsaro, but for now we'll just have to hard-code the size here
        if self.schemaversion == 1:
            tagheadersize = 35 + (4 * 8)

        if self.pktcontentlen <= tagheadersize:
            return 0

        return self.pktcontentlen - tagheadersize

    cpdef int setRsdosPacketString(self, const unsigned char[:] buf,
            const unsigned int maxlen):

        cdef parsedString astr


        astr = read_string(buf, maxlen, addNullTerm=False)
        if astr.toskip == 0:
            return 0
        self.packetcontent = astr.start
        self.pktcontentlen = astr.strlen
        self.sizeinbuf += astr.toskip + astr.strlen
        return 1

    cpdef void setSchemaVersion(self, const unsigned int schemaversion):
        self.schemaversion = schemaversion

@cython.final
cdef class AvroRsdosReader(AvroReader):

    def __init__(self, filepath):
        super().__init__(filepath)
        self.currentrec = AvroRsdos()
        self.schemaversion = 0

    cdef int _parseNextRecord(self, const unsigned char[:] buf,
            const unsigned int maxlen):

        cdef unsigned int offset, offinc
        cdef RsdosAttribute i
        cdef unsigned int maxattr

        if maxlen == 0:
            return 0
        offset = 0


        if self.schemaversion == 0:
            self.schemaversion = 1
            for f in self.schemajson['fields']:
                if "first_attack_port" == f['name']:
                    self.schemaversion = 2
                    break
            self.currentrec.setSchemaVersion(self.schemaversion)

        if self.schemaversion == 1:
            maxattr = ATTR_RSDOS_LATEST_TIME_USEC + 1
        elif self.schemaversion == 2:
            maxattr = ATTR_RSDOS_LAST_ATTRIBUTE
        else:
            return 0

        self.currentrec.resetRecord()
        for i in range(0, maxattr):
            offinc = self.currentrec.parseNumeric(buf[offset:],
                    maxlen - offset, i)
            if offinc == 0:
                return 0
            offset += offinc

        return self.currentrec.setRsdosPacketString(buf[offset:],
                maxlen - offset);


# vim: set sw=4 tabstop=4 softtabstop=4 expandtab :
