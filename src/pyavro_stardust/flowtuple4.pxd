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
