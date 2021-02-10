# Example code that uses the AvroFlowtupleReader extension class to
# count flowtuples via a perFlowtuple callback method

import sys
from pyavro_stardust import AvroFlowtupleReader

counter = 0

# Incredibly simple callback that simply increments a global counter for
# each flowtuple
def perFlowtupleCallback(ft):
    global counter
    counter += 1

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
    print(counter)

run()
