
This is a (mostly) complete 4.11 install, total is about 44MB in size.

On your PVE host:

```
 qm restore vzdump-qemu-105-2025_09_23-22_34_08.vma.zst vmid
```

Where vmid is of your choosing.

VM CONFIG:
  - 1 CPU
  - 128MB RAM
  - Standard VGA
  - Machine: i440fx
  - SCSI: LSI53C895A
  - Network: pcnet
  - 10GB disk (IDE0: DOS + NWSERVER + SYS)
  - 8GB disk  (IDE1: DATA)
  - DOS 6.22 (100MB C: drive)
  - CDROM Drivers installed (IDE3/UNIT 0 = R:)
  - AUTOEXEC STARTS C:\NWSERVER\SERVER.EXE
 
NETWARE 4.11:
  - NAME: STIMPY
  - IPX INTERNAL NET: DE3AFEED
  - NIC: AMD PCNET PCI (AUTODETECT)
  - IPX NETWORK (802.2): 05000042
  - SYS VOLUME: 7GB
  - DATA VOLUME: 8GB
  - DIRECTORY TREE: CORP
  - DIRECTORY CONTEXT: O=FABRIKAM
  - ADMIN NAME: CN=Admin.O=FABRIKAM
  - ADMIN PASSWORD: password
  - LEGACY NWADMIN INSTALLED
  - LONG FILE NAMES LOADED AND APPLIED


OBSERVED NETWORK EMISSIONS:

```
INIHQRTR01#sh ipx servers
Codes: S - Static, P - Periodic, E - EIGRP, H - Holddown, + = detail
U - Per-user static
3 Total IPX Servers

Table ordering is based on routing and server info

   Type Name                       Net     Address    Port     Route Hops Itf
P     4 STIMPY                DE3AFEED.0000.0000.0001:0451      2/01   1  Et1/1.42
P   26B CORP_________________ DE3AFEED.0000.0000.0001:0005      2/01   1  Et1/1.42
P   278 CORP_________________ DE3AFEED.0000.0000.0001:4006      2/01   1  Et1/1.42

```
