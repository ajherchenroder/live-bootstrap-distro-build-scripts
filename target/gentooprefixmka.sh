#!/bin/bash
# parse the input and assign it back to BOOTMETH
BOOTMETH = $1

cp /usr/src/linux/arch/x86/boot/bzImage /mnt/gentoo/boot/vmlinuz
cp /lfs-remount.sh /mnt/gentoo/lfs-remount.sh

if test "$BOOTMETH" = "1"; then 
   grub-install --target i386-pc /dev/$DISKTOUSE2
else 
   grub-install --target=x86_64-efi --removable
   grub-install --bootloader-id=LFS --recheck
fi 
echo "Gentoo Prefix installed. Reboot into the new system and run /gentoo/prefix/startprefix to enter the prfix"


