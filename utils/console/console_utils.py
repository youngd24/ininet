#!/usr/bin/env python3
"""
con.py

Find the console server port for a given host and telnet to it.

Copyright (c) who?
Darren Young [youngd24@gmail.com]

##############################################################################

REQUIREMENTS:

 - python3
 - dnspython
 - telnet

##############################################################################

USAGE:

 For those cases where you have something like a Cisco router acting as a
 serial console server, and those serial ports are telnet enabled, this is
 an easy way to not have to remember which port on which console server
 hosts the serial port for that device.

 Say you have the following console server, with port 2031 hosting the console
 for a server named sw01, in DNS:

 consrv01   IN  A   192.168.1.1

 The DNS records for server sw01 would look like this:

 sw01       IN  A   192.168.1.20
 sw01       IN  TXT "consvr=consrv01.mydomain.com, conport=2031"

 To access the console using this script, type "con sw01.mydomain.com", it will
 find that DNS record and spawn a telnet to that machine/port. Exit the usual
 way using ctrl-] on your computer.

 Tested on Linux (Debian & Ubuntu), MacOS (something) and Solaris 7.

##############################################################################

 NOTES:

  - Currently you have to pass in the FQDN of the machine to connect to

"""
import re
import sys
import subprocess
try:
    from dns import resolver
except ImportError:
    print('dnspython module is not installed. Please install it and try again.')
    sys.exit(1)

def query_txt_record(hostname: str):
    """Locate the TXT record in DNS.

    Record format is: "consvr=<server>, conport=<port>"
    """
    # do we care to support multiple TXT records, as failover?
    answer = resolver.resolve(hostname, 'TXT')[0]
    ptrn = r'consvr=(?P<srv>.*?), conport=(?P<port>\d+ ?)'
    result = re.search(ptrn, str(answer))
    if result:
        return result.group('srv'), result.group('port')

    raise resolver.NoAnswer('No matching TXT record found')

def spawn_telnet(hostname: str, port: int):
    """Spawn telnet for the connection. Use the usual ctrl-] to break out of it."""
    print(f'Opening telnet connection to {hostname} {port}...')
    subprocess.run(['telnet', hostname, str(port)], check=False)

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(f'Usage: {sys.argv[0]} <hostname>')
        sys.exit(2)

    try:
        host = sys.argv[1]
        consvr, conport = query_txt_record(host)
        spawn_telnet(consvr, int(conport))

    except resolver.NoAnswer:
        print(f'No TXT record found for {host}.')

    except resolver.NXDOMAIN:
        print(f'Host {host} does not exist.')

    except OSError as e:
        print(f'Error attempting to launch telnet: \n{e}')

    except KeyboardInterrupt:
        print('\nCancelling due to user request.')
