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
lsblk
read -p 'Select the disk /dev node to put the bootstrap on.> ' DISKTOUSE
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/$DISKTOUSE
  g # clear the in memory partition table
  n # new partition
  1 # partition number 1
    # default - start at beginning of disk 
  +1G # 1G uefi parttion
  t # change type
  1 # uefi
  n # new partition
  2 # partion number 2
    # default, start immediately after preceding partition
  +16G # swap partion
  t # change type
  19 # swap
  n # new partition
  4 # partion number 3
    # default, start immediately after preceding partition
    # default use the rest of the disk
  w # write the partition table
  q # and we're done
EOF
# Setup and enable a swap partition
mkswap /dev/$DISKTOUSE'2'
swapon /dev/$DISKTOUSE'2' 
# format and mount the target partition
mkfs.ext4 /dev/$DISKTOUSE''
mkdir /mnt/lfs
mount /dev/$DISKTOUSE'2' /mnt/lfs
cd /mnt/lfs
# format and mount the rest of the partitions
mkfs.vfat /dev/$DISKTOUSE'1'
mkdir /mnt/lfs/uefi
mount /dev/$DISKTOUSE'1' /mnt/lfs/uefi
# ready to start alfs
git clone https://git.linuxfromscratch.org/jhalfs.git jhalfs
cd jhalfs
make