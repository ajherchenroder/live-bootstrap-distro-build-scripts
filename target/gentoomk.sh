#! /bin/bash
#set up working directory
#
#Notes:
#Live bootstrap doesn't have the lsblk command, using fdisk -l to enumerated the drives.
#You need to be root to run this script
#
#decide where we are going to put things
echo "This script can make a stag3 and snapshot tarball or setup and install Gentoo on another drive."
read -p 'enter 1 for stage3/snapshot or 2 for full install (deafult is stage3/snapshot' FULLBUILD
mkdir /mnt/gentoo
fdisk -l | grep /dev
read -p 'Select the disk /dev node to build gentoo on. (sdxx) > ' DISKTOUSE
mount /dev/$DISKTOUSE /mnt/gentoo
if FULLBUILD==1 ; then
   read -p 'Select the disk /dev node to install the final gentoo on. (sdxx) > ' DISKTOUSE2
fi
#download gentoo files
mkdir /gentoosources
cd /gentoosources
curl http://distfiles.gentoo.org/snapshots/squashfs/gentoo-current.xz.sqfs -O -L
curl https://gitweb.gentoo.org/proj/portage.git/snapshot/portage-3.0.65.tar.bz2 -O -L
## Symlink python (needed for portage)
ln -sv python3 /usr/bin/python

# Install portage
tar -xvf portage-3.0.65.tar.bz2
cd portage-3.0.65
meson setup --prefix /usr build
meson install -C build




