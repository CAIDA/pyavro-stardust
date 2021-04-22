## pyavro-stardust

This package provides an interface for fast processing of the STARDUST avro
data files using python.

Data formats that are currently supported are:
 * flowtuple v3 data
 * flowtuple v4 data
 * RSDOS attack data

### Installation

Dependencies:
  * pywandio -- https://github.com/CAIDA/pywandio (note: STARDUST users should
    already have the python[3]-pywandio package installed on their VM)
  * cython


```
make && make install
```

or

```
USE_CYTHON=1 pip install --user .
```

### Examples
Simple example programs that demonstrate the API for each of the
supported formats can be found in the `examples/` directory.


### General Usage

I strongly recommend having the code for one of the examples available
when you read this section, as it should help clarify much of what is
being explained here.

---

Step 1: Create an instance of a reader for the data format that you wish to
read, passing in a valid wandio path to the file that you wish to read
as a parameter (a swift URI or a path to a file).

Examples of valid reader instances are: `AvroFlowtuple3Reader`,
`AvroFlowtuple4Reader`, and `AvroRsdosReader`.

Step 2: Invoke the `start()` method for the reader instance.

Step 3: Define a callback method that you wish to be invoked for each Avro
record that has been read from your input file.

The method must take two arguments: the record itself and a `userarg`
parameter. The `userarg` parameter provides a way for you to pass in
additional arguments to the callback method from outside of the scope
of the callback method.

There are some common methods that are available for any Avro record object:
 * `asDict()` -- returns all fields in the Avro record as a python dictionary
    (key = field name, value = field value).
 * `getNumeric(attributeId)` -- returns the value for a specific field that
   has a numeric value (e.g. IP address, port, counter, timestamp, etc.)
 * `getString(attributeId)` -- returns the value for a specific field that has
   a string value (e.g. a geo-location tag)
 * `getNumericArray(attributeId)` -- returns a list of values that have been
   stored in the record as an array of numbers

The attributeIds for each data format are listed on the pyavro-stardust wiki
at https://github.com/CAIDA/pyavro-stardust/wiki/Supported-Data-Formats

In terms of efficiency, I would recommend using `asDict()` if your callback
function needs to access more than 3 different fields in the record, as the
function call overhead of calling methods like `getNumeric()` multiple times
will quickly add up to exceed the cost of calling `asDict()` once and having
every value available.

Step 4: Invoke the `perAvroRecord()` method on your reader instance, passing
in your callback function name as the first argument. If your callback is
going to make use of the `userarg` parameter, then the intended value for
`userarg` should be passed in as the optional second argument.

This function call will only complete once your callback has been applied to
every individual Avro record in the input file.

Step 5: Invoke the `close()` method on your reader instance.

Step 6: Do any final post-processing or output writing that your analysis
requires.

