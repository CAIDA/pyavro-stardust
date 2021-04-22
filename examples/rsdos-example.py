# Example code that uses the AvroRsdosReader extension class to count
# DOS attacks via a perDos callback method

import sys
from pyavro_stardust.rsdos import AvroRsdosReader, RsdosAttribute, \
       AvroRsdos

count = 0
attack_pkts = 0

def perDosCallback(rsdos, userarg):
    global count, attack_pkts

    count += 1
    dos = rsdos.asDict()
    attack_pkts += dos['packet_count']

    # Ideally, we'd do things with the other fields in 'dos' as well,
    # but this is just intended to be a very simple example

def run():
    # sys.argv[1] must be a valid wandio path -- e.g. a swift URL or
    # a path to a file on disk
    reader = AvroRsdosReader(sys.argv[1])
    reader.start()

    # This will read all of the attack records and call `perDosCallback` on
    # each one
    reader.perAvroRecord(perDosCallback)
    reader.close()

    # Display our final results
    print("Attacks", count, "   Packets:", attack_pkts)

run()
