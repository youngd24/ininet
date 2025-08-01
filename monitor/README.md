# Introduction

Monitoring systems and networks in 1999 could be challenging, to say the least, especially when compared to today. Many of the systems, applications, and even concepts we're accustomed to simply did not exist then. This area brings to life some of the methods and tools we used back then to do our jobs.

# Syslog

At the core of monitoring in this environment is Syslog as it was many times in the past, and still is for that matter. I'm not going into details here, at least yet, Syslog configurations are in process but there are bits spread throughout this repo. The main takeaway is there's a Syslog server and everything sends to it.

# Swatch(dog)

# MRTG

# RT (Request Tracker)

# Files Here

What's in this directory?

```
|---------------------|---------------------------------------|
| NAME                | DESCRIPTION                           |
|---------------------|---------------------------------------|
| swatch              | Shell script to call swatchdog        |
| swatchdogrc         | Configuration file for swatchdog      |
| swatchdog.service   | systemd unit for for swatchdog        |
| asa_block_ip.expect | expect script to block IP's in an ASA |
|---------------------|---------------------------------------|
```

