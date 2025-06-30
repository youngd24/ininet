#!/usr/bin/env python3
###############################################################################
#
# con.py
#
# Find the console server port for a given host and telnet to it.
#
# Copyright (c) who?
# Darren Young [youngd24@gmail.com]
#
###############################################################################
#
# REQUIREMENTS:
#
# - python3
# - dnspython
# - telnet
#
###############################################################################
#
# USAGE:
#
# For those cases where you have something like a Cisco router acting as a
# serial console server, and those serial ports are telnet enabled, this is
# an easy way to not have to remember which port on which console server
# hosts the serial port for that device.
#
# Say you have the following console server, with port 2031 hosting the console
# for a server named sw01, in DNS:
#
# consrv01   IN  A   192.168.1.1
#
# The DNS records for server sw01 would look like this:
#
# sw01       IN  A   192.168.1.20
# sw01       IN  TXT "consvr=consrv01.mydomain.com, conport=2031"
#
# To access the console using this script, type "con sw01", it will find that
# DNS record and spawn a telnet to that machine/port. Exit the usual way using
# ctrl-] on your computer.
#
# Tested on Linux (Debian & Ubuntu), MacOS (something) and Solaris 7.
#
###############################################################################
#
# NOTES:
#
# - Currently you have to pass in the FQDN of the machine to connect to
#
###############################################################################

# imports
import sys
import dns.resolver
import subprocess


# -----------------------------------------------------------------------------
# Locate the TXT record in DNS
# Record format is: "consvr=<server>, conport=<port>"
# -----------------------------------------------------------------------------
def query_txt_record(hostname):
    try:
        answers = dns.resolver.resolve(hostname, 'TXT')
        for rdata in answers:
            for txt_string in rdata.strings:
                decoded = txt_string.decode('utf-8')
                if 'consvr=' in decoded and 'conport=' in decoded:
                    parts = decoded.split(',')
                    data = {}
                    for part in parts:
                        key_value = part.strip().split('=')
                        if len(key_value) == 2:
                            key, value = key_value
                            data[key.strip()] = value.strip()
                    if 'consvr' in data and 'conport' in data:
                        return data['consvr'], data['conport']
        print("No matching TXT record found.")
        return None, None
    
    except dns.resolver.NoAnswer:
        print(f"No TXT record found for {hostname}")
        return None, None
    
    except dns.resolver.NXDOMAIN:
        print(f"Host {hostname} does not exist")
        return None, None
    
    except Exception as e:
        print(f"An error occurred: {e}")
        return None, None

# -----------------------------------------------------------------------------
# spawn a telnet for the connection
# use the usual ctrl-] to break out of it
# -----------------------------------------------------------------------------
def spawn_telnet(host, port):
    try:
        print(f"Spawning telnet to {host} {port}...")
        subprocess.run(['telnet', host, port])
    
    except FileNotFoundError:
        print("Error: 'telnet' command not found. Is it installed?")
    
    except Exception as e:
        print(f"Failed to start telnet: {e}")



# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <hostname>")
        sys.exit(1)

    hostname = sys.argv[1]
    consvr, conport = query_txt_record(hostname)

    if consvr and conport:
        spawn_telnet(consvr, conport)

