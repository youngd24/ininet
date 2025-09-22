For the video here: https://youtu.be/DyyU7hQ0cMk

To add to the pve config file:

args: -drive 'file=/var/lib/vz/template/iso/DOS622_disk1.img,if=floppy,index=0'

To change the floppy disk images:

root@pve01:/etc/pve/qemu-server# qm monitor 103
Entering QEMU Monitor for VM 101 - type 'help' for help

qm> change floppy0 /var/lib/vz/template/iso/DOS622_disk2.img
qm> change floppy0 /var/lib/vz/template/iso/DOS622_disk3.img
qm> change floppy0 /var/lib/vz/template/iso/DOS_CDROM.img

DOS cdrom drivers are in the cdrom.zip file
