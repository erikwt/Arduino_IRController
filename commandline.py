#!/usr/bin/env python

import serial
import sys

RETURN = '\n'

# Connect to the Arduino
s = serial.Serial('/dev/ttyUSB1', 9600, timeout=60)

print "Connected to serial port. Use control^C or control^D to exit."

while True:
    try:
        input = raw_input("# ")
        s.flushInput()
        s.write(input + RETURN + RETURN)
        got_return = False

        while True:
            try:
                output = s.read()
                if(output == RETURN):
                    if(got_return): break
                    got_return = True
                else: got_return = False
                sys.stdout.write(output)
            except KeyboardInterrupt:
                print "Interrupted by user"
                break
    except (KeyboardInterrupt, EOFError):
        print "\nGot 'quit' from user. Bye!"
        s.close()
        sys.exit()
