
cdef struct parsedString:
    int toskip
    int strlen
    unsigned char *start

cdef (int, long) read_long(const unsigned char[:] buf, const int maxlen)
cdef parsedString read_string(const unsigned char[:] buf, const int maxlen)

cdef class AvroRecord:

    cdef long *attributes_l
    cdef char **attributes_s
    cdef unsigned int sizeinbuf
    cdef int stringcount;
    cdef int numcount;

    cdef int parseNumeric(self, const unsigned char[:] buf, const int maxlen,
        int attrind)
    cpdef long getNumeric(self, int attrind)
    cpdef str getString(self, int attrind)
    cpdef unsigned int getRecordSizeInBuffer(self)
    cdef int parseString(self, const unsigned char[:] buf, const int maxlen,
        int attrind)
    cpdef void resetRecord(self)


cdef class AvroReader:
    cdef unsigned int nextblock
    cdef unsigned int unzip_offset
    cdef fh
    cdef str filepath
    cdef bytearray syncmarker
    cdef bytearray bufrin
    cdef bytes unzipped
    cdef AvroRecord currentrec

    cpdef void _readAvroFileHeader(self)
    cdef int _parseNextRecord(self, const unsigned char[:] buf,
                 const int maxlen)
    cdef AvroRecord _getNextRecord(self)

# vim: set sw=4 tabstop=4 softtabstop=4 expandtab :
