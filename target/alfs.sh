#!/usr//bin/bash
#set -e
mount -vt devtmpfs devtmpfs /dev
mount -vt proc proc /proc
mount -vt sysfs sysfs /sys
mount -vt tmpfs tmpfs /run
mount -t tmpfs -o nosuid,nodev tmpfs /dev/shm
mount -vt devpts devpts -o mode=0625 /dev/pts
chmod 777 /etc
chmod 777 /sys
chmod 777 /tmp
chmod 777 /usr
#lsblk
#read -p "Enter the partition to build on (sdxx) -> " USEPART
#if ! test -d /mnt
#then   
#   mkdir /mnt
#fi
#if ! test -d /mnt/buildroot
#then
#   mkdir /mnt/buildroot
#fi
#mount -v -t ext4 /dev/$USEPART /mnt/buildroot
#cd /mnt/buildroot
git clone https://git.linuxfromscratch.org/jhalfs.git jhalfs
cd jhalfs
make
echo "Ready to run ALFS"