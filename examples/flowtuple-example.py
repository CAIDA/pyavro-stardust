# Example code that uses the AvroFlowtupleReader extension class to
# count flowtuples via a perFlowtuple callback method

import sys
from collections import defaultdict
from pyavro_stardust import AvroFlowtupleReader, FlowtupleAttributeNum, \
        FlowtupleAttributeStr

counter = 0
protocols = defaultdict(int)

# Incredibly simple callback that simply increments a global counter for
# each flowtuple, as well as tracking the number of packets for each
# IP protocols
def perFlowtupleCallback(ft):
    global counter, protocols
    counter += 1

    proto = ft.getNumeric(FlowtupleAttributeNum.ATTR_FT_PROTOCOL)
    pktcnt = ft.getNumeric(FlowtupleAttributeNum.ATTR_FT_PKT_COUNT)

    # Note: use ft.getString(FlowtupleAttributeStr) for string attributes

    protocols[proto] += pktcnt

def run():

    # sys.argv[1] must be a valid wandio path -- e.g. a swift URL or
    # a path to a file on disk
    ftreader = AvroFlowtupleReader(sys.argv[1])
    ftreader.start()

    # This will read all flowtuples and call `perFlowtupleCallback` on
    # each one
    ftreader.perFlowtuple(perFlowtupleCallback)

    ftreader.close()

    # Display our final result
    print("Total flowtuples:", counter)
    for k,v in protocols.items():
        print("Protocol", k, ":", v, "packets")

run()
