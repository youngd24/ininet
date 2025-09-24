Pre-built DOS 6.22 Netware VLM client Proxmox VM based on my video here:

Virtual Machine:

- Machine: i440fx
- Memory: 64MB
- Display: Standard VGA
- SCSI: LSI 53C895A
- IDE0: 8GB disk
- IDE2: CDROM
- NIC: AMD PCNet (change the MAC)

DOS 6.11 Installation:

- 2GB DOS Partition
- MS-DOS 6.22
- CD-ROM drivers
- Netware VLM client 1.21 (pcnet odi driver)

To import into Proxmox:

- Transfer the file(s) from the vzdump directory up to the pve host
- SSH into it

```
qmrestore vzdump-qemu-101-2025_09_24-11_37_44.vma.zst <vmid>
```

Where vmid is whatever numeric ID you want to assign to it.

I don't know why you can't rename these files, but for whatever reason whenever I do it won't accept them.

Bring up your Netware server, make sure it's on the same network then start up this machine. Once it's up, type:

```F:\LOGIN```
