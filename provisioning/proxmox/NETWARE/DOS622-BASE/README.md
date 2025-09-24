
Pre-build DOS 6.22 Proxmox VM based on my video here: https://youtu.be/0ChB3Ewdngk

- 10GB disk
- 100MB DOS partition
- MS-DOS 6.22
- CD-ROM drivers

This one is ready for a Netware 4.11 installation, add your Netware ISO and
license floppy.

To import into Proxmox:

- Transfer the file up to the pve host
- SSH into it

```
qmrestore vzdump-qemu-110-2025_09_23-13_31_45.vma.zst <vmid>
```

Where vmid is whatever numeric ID you want to assign to it.

I don't know why you can't rename these files, but for whatever reason whenever I do it won't accept them.

This one has a floppy attached with a non-existent license file, replace that file name with yours. The args part is commented out, remove the comment and clean up the %3A thing that something keeps adding (replace it with a colon).

I changed the NIC to the AMD PCNet one in the config file, you can't do that in the UI. Change the MAC address.
