#!/bin/bash
#mount the kernel file systems
mount -vt devtmpfs devtmpfs /dev
mount -vt devpts devpts /dev/pts
mount -vt proc proc /proc
mount -vt sysfs sysfs /sys
mount -vt tmpfs tmpfs /run
mount -t tmpfs -o nosuid,nodev tmpfs /dev/shm

# parse the input and assign it back to BOOTMETH
BOOTMETH=$1
DISKTOUSE2=$2
read -p 'BOOTMETH = '$BOOTMETH', DISKTOUSE2 = '$DISKTOUSE2' JUNK
if test "$BOOTMETH" = "1"; then 
   grub-install --target i386-pc /dev/$DISKTOUSE2
else 
   grub-install --target=x86_64-efi --removable
   grub-install --bootloader-id=LFS --recheck
fi 
echo "Gentoo Prefix installed. Reboot into the new system and run /gentoo/prefix/startprefix to enter the prfix"


