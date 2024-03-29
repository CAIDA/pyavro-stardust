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
