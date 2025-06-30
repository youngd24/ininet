# con
A simple little utility to enable me to be a slightly lazier than normal.

# The Problem
Say you have a Cisco 2900, with a 16 port async serial board, that acts as the console server for a bunch of other gear, maybe other Cisco devices. IOS takes all of those serial ports and, if configured correctly, makes them available as tcp ports on the network one can telnet to. So, say one is mapped is line 33 on the 2900, you could do this to access that port over the network:

> `telnet <host> 2033`

Issues:

* I can never remember which port is which device.
* It contains more text than I want to type.

# Solution

What if I could do a lookup in some way for where that thing is attached and have it just telnet for me? Ideally it would be centralized in something, a database, etc, so what to use? Well, could do just that, stash it in a database but that seems like overkill that just adds too much effort. Where else is centralized, always available, easy to access and already maintained?

> `It's not DNS. It might be DNS. It's DNS`

Ok, so DNS it is. How cnaa I attach some info to the DNS for the host saying where it's attached? I'd need the following information:

1. The name of the console server hosting it.
2. The tcp port number presented for it.

I first thought I could maybe use the WKS record type but after reading, it's essentailly a dead record type. Ok, SRV records? No, those are desgined for domain level service info, not host level. Hmmm... How about just abusing the TXT record like always?

Settled. The format will be:

host   IN TXT "consvr=<host>, conport=<port>"

And that will be attached to the DNS record for the given entry. Example from the code:

```
# Say you have the following console server, with port 2031 hosting the console
# for a server named sw01, in DNS:
#
# consrv01   IN  A   192.168.1.1
#
# The DNS records for server sw01 would look like this:
#
# sw01       IN  A   192.168.1.20
# sw01       IN  TXT "consvr=consrv01.mydomain.com, conport=2031"
```

Then all I'd have to type to get where I wantd to is:

> `con host`

So I wrote it. Well, not really, I had ChatGPT do it, here's the prompt chain:

```
You asked for a Python script with the following capabilities:

1. DNS TXT Record Query
Query DNS for a TXT record of a hostname. The TXT record contains two fields:
consvr=host, conport=port.

2. Command-Line Argument Input
The script should take the hostname as the first argument passed on the command line.

3. Spawn Telnet Session
Use the extracted consvr and conport to spawn a telnet session to that server and port.
```

It could probably be better but who cares. Code is in here and I've taken credit for it. Enjoy.

Oh, there are C versions for Linux and Solaris 7 in here as well, 'cause, why not. ChatGPT did those as well. We're doomed.

Laterz.