#!/bin/bash
# parse the input and assign it back to BOOTMETH
BOOTMETH=$1
read -p 'BOOTMETH = $BOOTMETH ' JUNK
if test "$BOOTMETH" = "1"; then 
   grub-install --target i386-pc /dev/$DISKTOUSE2
else 
   grub-install --target=x86_64-efi --removable
   grub-install --bootloader-id=LFS --recheck
fi 
echo "Gentoo Prefix installed. Reboot into the new system and run /gentoo/prefix/startprefix to enter the prfix"


