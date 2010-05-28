#!/usr/bin/env python

import serial
import sys

# Connect to the Arduino
s = serial.Serial('/dev/ttyUSB0', 9600, timeout=60)

print "Connected to serial port. Use control^C or control^D to exit."

while True:
    try:
        input = raw_input("# ")
        s.write(input + '\n')
        print s.readline(),
    except (KeyboardInterrupt, EOFError):
        print "\nGot 'quit' from user. Bye!"
        s.close()
        sys.exit()
