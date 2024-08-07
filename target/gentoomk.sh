#!/bin/bash
# based on gentoo.txt located at https://mid-kid.root.sx/git/mid-kid/bootstrap in the gentoo-2024 folder
# 
#MIT License
#
#Copyright (c) 2017 Braintree
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.


#set up working directory
#
#Notes:
#
#You need to be root to run this script
#
#decide where we are going to put things
echo "This script can make a stage 3 and snapshot tarball or setup and install Gentoo on another drive."
read -p 'enter 1 for a stage 3 snapshot or 2 for full install (default is stage 3/snapshot > ' FULLBUILD
mkdir /mnt/gentoo
lsblk
read -p 'Select the disk /dev node to build gentoo on. (sdxx) > ' DISKTOUSE
mount /dev/$DISKTOUSE /mnt/gentoo
if [$FULLBUILD="2"]; then
   read -p 'Select the disk /dev node to install the final gentoo on. (sdx) > ' DISKTOUSE2
fi
mkdir /gentoo
chmod 777 /gentoo

# Set up passswd and group for portage
echo 'portage:x:250:250:portage:/var/tmp/portage:/bin/false' >> /etc/passwd
echo 'portage::250:portage' >> /etc/group

#network and locale stuff
echo 'nameserver 192.168.2.3' > /etc/resolv.conf
#echo 'nameserver 1.1.1.1' > /etc/resolv.conf
echo 'en_US.UTF-8' > /etc/locale.gen

#prep for prefix
export EPREFIX="/gentoo/prefix"
export PATH="${EPREFIX}/usr/bin:${EPREFIX}/bin:${EPREFIX}/tmp/usr/bin:${EPREFIX}/tmp/bin:$PATH"
export LATEST_TREE_YES=0

#prefix stage 1
/target/gentooprefix.sh ${EPREFIX} stage1 


#prefix stage 2

/target/gentooprefix.sh ${EPREFIX} stage2 

#prefix stage 3
#requires twice through to complete
/target/gentooprefix.sh ${EPREFIX} stage3 
/target/gentooprefix.sh ${EPREFIX} stage3 

exit 0

# mount and build the partition that will become stage 3
su -c /target/gentoomk2.sh

mkdir /output
tar cf /output/gentoo-livebootstrap-stage3.tar -C /mnt/gentoo 
xz -9v /output/gentoo-livebootstrap-stage3.tar 
echo "The live bootstrap stage 3 file is located in the /output directory"
if [$FULLBUILD="1"]; then
   #Test trap then exit
   read -p 'post partition stage3 trap> ' BOOTSTRAPPED
   exit 0
fi

#set up disks for the final system using GPT and UEFI
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/$DISKTOUSE2
  g # clear the in memory partition table
  n # new partition
  1 # partition number 1
    # default - start at beginning of disk 
  +1G # 8G swap parttion
  t # change type
  1 # UEFI
  n # new partition
  2 # partion number 2
    # default, start immediately after preceding partition
  +8G # 8G swap parttion
  t # change type
  2 # select partition 2
  19 # linux swap
  n # new partition
  3 # partion number 3
    # default, start immediately after preceding partition
    # default use the rest of the disk
  w # write the partition table
  q # and we're done
EOF
#Test trap
read -p 'post partition build trap2> ' BOOTSTRAPPED

#format file systems
#format the UEFI partion to vfat 
mkfs.vfat /dev/$DISKTOUSE2'1'
# Setup and enable a swap partition
mkswap /dev/$DISKTOUSE2'2'
swapon /dev/$DISKTOUSE2'2' 
# format the rest of the partitions
mkfs.ext4 /dev/$DISKTOUSE2'3'

#Test trap
read -p 'system build build trap> ' BOOTSTRAPPED

