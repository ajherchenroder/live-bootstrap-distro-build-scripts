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
echo "This script can setup and install a Gentoo prefix on another drive."
mkdir /mnt/gentoo
lsblk
read -p 'Select the disk /dev node to install the final gentoo on. (sdx) > ' DISKTOUSE2
read -p 'Enter the host name for the new install > ' HOSTN
read -p 'Enter the Fully Qualified Domain Name (FQDM) name for the new install > ' FQDM
read -p 'Enter 1 for DOS MBR booting and 2 for UEFI (Default) > ' BOOTMETH
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

# mount and build the partition that will become stage 3
# UEFI or MBR boot
#MBR
#setup MBR partitions
if test "$BOOTMETH" = "1"; then 
  sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/$DISKTOUSE2
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
  +8G # 8G swap parttion
  t # change type
  82 # linux
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
    # default use the rest of the disk
  a # mark a partition
  1 # mark partition 1 as active
  w # write the partition table
EOF
#format partitions
# Setup a swap partition
mkswap -f /dev/$DISKTOUSE2'1'
# format the target partitions
mkfs.ext4 -F /dev/$DISKTOUSE2'2'
else
#UEFI
#setup GPT partitions
  sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/$DISKTOUSE2
  g # clear the in memory partition table
  n # new partition
  1 # partition number 1
    # default - start at beginning of disk 
  +1G # 1G boot parttion
  t # change type
  1 # EFI
  n # new partition
  2 # partion number 2
    # default, start immediately after preceding partition
  +8G # swap partion
  t # change type
  2 # partion number 2
  19 # linux swap
  n # new partition
  3 # partion number 3
    # default, start immediately after preceding partition
    # default use the rest of the disk
  t # change type
  3 # partion number 3
  20 # linux
  w # write the partition table
EOF
#format partitions
# Setup a swap partition
mkswap -f /dev/$DISKTOUSE2'2'
# format the target partitions
mkfs.vfat -I -F32 /dev/$DISKTOUSE2'1' #EFI partition needs FAT32
mkfs.ext4 -F /dev/$DISKTOUSE2'3'
fi
#
#build MBR GRUB
if test "$BOOTMETH" = "1"; then 
   cd /sources
   tar -xvf grub-2.06.tar.xz
   cd grub-2.06
   patch -Np1 -i ../grub-2.06-upstream_fixes-1.patch
   ./configure --prefix=/usr --sysconfdir=/etc --disable-efiemu --disable-werror
   make
   make install
   mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
   cd /sources
   rm -Rf grub-2.06
#build UEFI Grub
else
   cd /sources   
   tar -xvf grub-2.06.tar.xz
   cd grub-2.06
   patch -Np1 -i ../grub-2.06-upstream_fixes-1.patch
   ./configure --prefix=/usr --sysconfdir=/etc --disable-efiemu --disable-werror --with-platform=efi --target=x86_64
   make
   make install
   mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
   cd /sources
   rm -Rf grub-2.06 
   tar -xvf mandoc-1.14.6.tar.gz
   cd mandoc-1.14.6
   ./configure
   make mandoc
   install -vm755 mandoc   /usr/bin
   install -vm644 mandoc.1 /usr/share/man/man1
   cd /sources
   rm -Rf mandoc-1.14.6
   tar -xvf efivar-38.tar.bz2
   cd efivar-38
   sed '/prep :/a\\ttouch prep' -i src/Makefile
   make ERRORS=
   make install LIBDIR=/usr/lib
   cd /sources
   rm -Rf efivar-38
   tar -xvf efibootmgr-18.tar.gz
   cd efibootmgr-18
   make EFIDIR=LFS EFI_LOADER=grubx64.efi
   make install EFIDIR=LFS
   cd /sources
   rm -Rf efivar-38
fi
## grab the gentoo kernel sources and build them under lfs
mkdir /usr/src/linux
/gentoo/prefix/usr/bin/emerge --oneshot sys-kernel/gentoo-sources
cp -r /gentoo/prefix/usr/src/*gentoo/* /usr/src/linux
cd /usr/src/linux
make defconfig
make
make modules_install
# bzImage kernel is in /usr/src/linux/arch/x86/boot/ we will move it when we set up for grub
# install LFS bootscripts
cd /sources
tar -xvf lfs-bootscripts-20230728.tar.xz
cd lfs-bootscripts-20230728
make install
cd /sources
rm -Rf lfs-bootscripts-20230728
#perform additional configuration
chmod +x /usr/lib/udev/init-net-rules.sh
bash /usr/lib/udev/init-net-rules.sh
#dhcpcd and network setup
cd /sources
tar -xvf dhcpcd-10.0.2.tar.xz
cd dhcpcd-10.0.2
./configure --prefix=/usr --sysconfdir=/etc  --libexecdir=/usr/lib/dhcpcd --dbdir=/var/lib/dhcpcd \
--runstatedir=/run  --disable-privsep
make
make install
cd /sources
rm -Rf dhcpcd-10.0.2
tar -xvf blfs-bootscripts-20230824.tar.xz
cd blfs-bootscripts-20230824
make install-service-dhcpcd
cd /sources
cat > /etc/sysconfig/ifconfig.eth0 << "EOF"
ONBOOT="yes"
IFACE="eth0"
SERVICE="dhcpcd"
DHCP_START="-b -q -h ''<insert appropriate start options here>"
DHCP_STOP="-k <insert additional stop options here>"
EOF
cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf
# set to personal right now Google commented out
#nameserver 8.8.8.8
#nameserver 8.8.4.4.
nameserver 192.168.2.3
# End /etc/resolv.conf
EOF
touch /etc/hostname
echo $HSTN >> /etc/hostname
touch /etc/hosts
echo "127.0.0.1 localhost.localdomain localhost" >> /etc/hosts
echo "127.0.1.1 " $FQDM " " $HSTN >> /etc/hosts 
#
#configure inittab
cat > /etc/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S06:once:/sbin/sulogin
s1:1:respawn:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600

# End /etc/inittab
EOF
# 
#Configure time
cat > /etc/sysconfig/clock << "EOF"
# Begin /etc/sysconfig/clock

UTC=0

# Set this to any options you might need to give to hwclock,
# such as machine hardware clock type for Alphas.
#CLOCKPARAMS=

# End /etc/sysconfig/clock
EOF
#create the standardized portion of the fstab
cat > /etc/fstab << "EOF"
# file system  mount-point    type     options             dump  fsck
#                                                                order

/dev/<zzz>     /              <fff1>    defaults            1     1
###/dev/<xxx>     /boot          <fff2>    defaults            1     2
/dev/<yyy>     swap           swap     pri=1               0     0
proc           /proc          proc     nosuid,noexec,nodev 0     0
sysfs          /sys           sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts       devpts   gid=5,mode=620      0     0
tmpfs          /run           tmpfs    defaults            0     0
devtmpfs       /dev           devtmpfs mode=0755,nosuid    0     0
tmpfs          /dev/shm       tmpfs    nosuid,nodev        0     0

# End /etc/fstab
EOF


# Create the customized portion for the fstab
# for mbr boot
if test "$BOOTMETH" = "1"; then 
   sed -i "s/<zzz>/sda2/g" /etc/fstab
   sed -i "s/<yyy>/sda1/g" /etc/fstab
   sed -i "s/<fff1>/ext4/g" /etc/fstab
else #for UEFI/GPT
   sed -i "s/###//g" /etc/fstab
   sed -i "s/<zzz>/sda3/g" /etc/fstab
   sed -i "s/<xxx>/sda1/g" /etc/fstab
   sed -i "s/<yyy>/sda2/g" /etc/fstab
   sed -i "s/<fff1>/ext4/g" /etc/fstab
   sed -i "s/<fff2>/vfat/g" /etc/fstab
   echo "efivarfs /sys/firmware/efi/efivars efivarfs defaults 0 0" >> /etc/fstab  
fi
##mount the target drive in preparation for copying
mount /dev/$DISKTOUSE2'2' /mnt/gentoo
mkdir /mnt/gentoo/boot
mkdir /mnt/gentoo/boot/grub
if test "$BOOTMETH" = "2"; then
   mount /dev/$DISKTOUSE2'1' /mnt/gentoo/boot
fi
#copy files over
cp -R /etc/ /mnt/gentoo/
cp -R /home/ /mnt/gentoo/
cp -R /opt/ /mnt/gentoo/
cp -R /srv/ /mnt/gentoo/
cp -R /usr/ /mnt/gentoo/
cp -R /var/ /mnt/gentoo/
cp -r /bin /mnt/gentoo
cp -r /lib /mnt/gentoo
cp -r /sbin /mnt/gentoo
cp -r /gentoo /mnt/gentoo
mkdir /mnt/gentoo/tmp
mkdir /mnt/gentoo/proc
mkdir /mnt/gentoo/sys
mkdir /mnt/gentoo/dev
mkdir /mnt/gentoo/dev/pts
mkdir /mnt/gentoo/dev/shm
mkdir /mnt/gentoo/run
# set up grub on the new disk
# for mbr boot
if test "$BOOTMETH" = "1"; then 
   grub-install --target i386-pc /dev/$DISKTOUSE2
   cp -R /boot/ /mnt/gentoo/
   cat > /mnt/gentoo/boot/grub/grub.cfg << "EOF"
   # Begin /boot/grub/grub.cfg
   set default=0
   set timeout=5

   insmod part_gpt
   insmod ext2
   set root=(hd0,2)

   menuentry "GNU/Linux, Linux 6.4.12-lfs-12.0" {
           linux   /vmlinuz root=/dev/sda2 ro net.ifnames=0
   }
EOF
else 
   grub-install --target=x86_64-efi --removable
   grub-install --bootloader-id=LFS --recheck
   cp -R /boot/ /mnt/gentoo/
   cat > /mnt/gentoo/boot/grub/grub.cfg << EOF
   # Begin /boot/grub/grub.cfg
   set default=0
   set timeout=5

   insmod part_gpt
   insmod ext2
   set root=(hd0,2)

   insmod all_video
   if loadfont /boot/grub/fonts/unicode.pf2; then
   terminal_output gfxterm
   fi

   menuentry "GNU/Linux, Linux 6.4.10-lfs-12.0"  {
   linux   /boot/vmlinuz root=/dev/sda2 ro net.ifnames=0
   }

   menuentry "Firmware Setup" {
     fwsetup
   }
EOF
cp -R /boot/ /mnt/gentoo/
fi  
echo "Gentoo Prefix installed. Reboot into the new system and run /gentoo/prefix/startprefix to enter the prfix"


