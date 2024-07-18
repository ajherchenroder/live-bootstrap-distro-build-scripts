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
read -p 'enter 1 for stage 3/snapshot or 2 for full install (default is stage 3/snapshot > ' FULLBUILD
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
#BOOTSTRAPPED="n"
#while [[ "$BOOTSTRAPPED" == "n" ]];
#do
   /target/gentooprefix.sh ${EPREFIX} stage1 
#   read -p 'Did the stage 1 bootstrap complete successfully? (y or n)> ' BOOTSTRAPPED
#   if [ "$BOOTSTRAPPED" == "y" ]; then
#      break 
#   fi
#done

#prefix stage 2

#BOOTSTRAPPED="n"
#while [[ "$BOOTSTRAPPED" == "n" ]];
#do
   /target/gentooprefix.sh ${EPREFIX} stage2 
#   read -p 'Did the stage 2 bootstrap complete successfully? (y or n)> ' BOOTSTRAPPED
#   if [ "$BOOTSTRAPPED" == "y" ]; then
#      break 
#   fi
#done


#prefix stage 3
BOOTSTRAPPED="n"
while [[ "$BOOTSTRAPPED" == "n" ]];
do
   /target/gentooprefix.sh ${EPREFIX} stage3 
   read -p 'Did the stage 3 bootstrap complete successfully? (y or n)> ' BOOTSTRAPPED
   if [ "$BOOTSTRAPPED" == "y" ]; then
      break 
   fi
done

#set up environment
#unset EPREFIX

# Rebuild and install everything into a new root, completely cleaning out LFS
USE=build emerge --root /mnt/gentoo sys-apps/baselayout

#set up environment continued
#export EPREFIX="/mnt/gentoo"
#export ROOT="/mnt/gentoo"
#export SYSROOT= "/mnt/gentoo"

#make.conf
#cat > /mnt/gentoo/etc/portage/make.conf << 'EOF'
#FEATURES='-news -pid-sandbox'
#MAKEOPTS="-j2"
#EMERGE_DEFAULT_OPTS="--jobs 1"
#CONFIG_PROTECT='-* /etc/locale.gen'
#CFLAGS="-march=x86-64 -pipe"
#CXXFLAGS="${CFLAGS}"
#USE='-nls ABI_86="64"'
#EOF

#echo 'nameserver 192.168.2.3' > /mnt/gentoo/etc/resolv.conf
#echo 'nameserver 1.1.1.1' > /mnt/gentoo/etc/resolv.conf
#echo 'en_US.UTF-8' > /mnt/gentoo/etc/locale.gen

#emerge --root /mnt/gentoo @system
#read -p 'Did the bootstrap complete successfully? (y or n)> ' BOOTSTRAPPED

# Pack it up
#tar cf /gentoo-bootstrap.tar -C /mnt/gentoo .
#xz -9v /gentoo-bootstrap.tar
#mkdir /mnt/gentoo/release
#cp /gentoo-bootstrap.tar.xz /mnt/gentoo/release
# stop if only building a stage 3
#
#if [FULLBUILD==1] ; then
#   echo "The Gentoo bootstrap stage 3 is located in /mnt/gentoo/release"
#   exit 0
#fi

#Create gentoo chroot

#echo "Building the Gentoo Chroot"