
Pre-build DOS 6.22 Proxmox VM for this video: https://youtu.be/0ChB3Ewdngk

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
qmrestore vzdump-qemu-105-2025_09_22-23_57_12.vma.zst <vmid>
```

Where vmid is whatever numeric ID you want to assign to it.
