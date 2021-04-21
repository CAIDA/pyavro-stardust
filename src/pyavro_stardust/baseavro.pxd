from libcpp.vector cimport vector

cdef struct parsedString:
    unsigned int toskip
    unsigned int strlen
    unsigned char *start

cdef struct parsedNumericArrayBlock:
    unsigned int totalsize
    unsigned int blockcount
    long *values


cdef (unsigned int, long) read_long(const unsigned char[:] buf,
        const unsigned int maxlen)
cdef parsedString read_string(const unsigned char[:] buf,
        const unsigned int maxlen)
cdef parsedNumericArrayBlock read_numeric_array(const unsigned char[:] buf,
        const unsigned int maxlen)

cdef class AvroRecord:

    cdef long *attributes_l
    cdef char **attributes_s
    cdef long **attributes_na
    cdef long *attributes_na_sizes
    cdef unsigned int sizeinbuf
    cdef unsigned int stringcount
    cdef unsigned int numcount
    cdef unsigned int numarraycount

    cdef int parseNumeric(self, const unsigned char[:] buf,
        const unsigned int maxlen, const int attrind)
    cpdef long getNumeric(self, const int attrind)
    cpdef str getString(self, const int attrind)
    cdef unsigned int getRecordSizeInBuffer(self)
    cdef unsigned int parseNumericArray(self, const unsigned char[:] buf,
            const unsigned int maxlen, const int attrind)
    cdef unsigned int parseString(self, const unsigned char[:] buf,
            const unsigned int maxlen, const int attrind)
    cpdef vector[long] getNumericArray(self, const int attrind)
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
                 const unsigned int maxlen)
    cdef AvroRecord _getNextRecord(self)
    cpdef void perAvroRecord(self, func, userarg=*)

# vim: set sw=4 tabstop=4 softtabstop=4 expandtab :
