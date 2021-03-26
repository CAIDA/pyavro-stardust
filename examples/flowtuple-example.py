# Example code that uses the AvroFlowtuple3Reader extension class to
# count flowtuples via a perFlowtuple callback method

import sys
from collections import defaultdict
from pyavro_stardust.flowtuple3 import AvroFlowtuple3Reader, \
        Flowtuple3AttributeNum, Flowtuple3AttributeStr

counter = 0
protocols = defaultdict(int)

# Incredibly simple callback that simply increments a global counter for
# each flowtuple, as well as tracking the number of packets for each
# IP protocols
def perFlowtupleCallback(ft, userarg):
    global counter, protocols
    counter += 1

    a = ft.asDict()
    proto = a["protocol"]
    pktcnt = a["packets"]

    protocols[proto] += pktcnt

def run():

    # sys.argv[1] must be a valid wandio path -- e.g. a swift URL or
    # a path to a file on disk
    ftreader = AvroFlowtuple3Reader(sys.argv[1])
    ftreader.start()

    # This will read all flowtuples and call `perFlowtupleCallback` on
    # each one
    ftreader.perAvroRecord(perFlowtupleCallback)

    ftreader.close()

    # Display our final result
    print("Total flowtuples:", counter)
    for k,v in protocols.items():
        print("Protocol", k, ":", v, "packets")

run()
