#! /bin/bash
#set up working directory
#
#Notes:
#Live bootstrap doesn't have the lsblk command, using fdisk -l to enumerated the drives.
#You need to be root to run this script
#
##set up environment variables
export XCC=clang
export XCXX=clang++
export XCPP=clang-cpp
export XLD=ld.lld
#
mkdir /mnt/freebsd
fdisk -l | grep /dev
read -p 'Select the disk /dev node to build freebsd on. (sdxx) > ' DISKTOUSE
mount /dev/$DISKTOUSE /mnt/freebsd
git clone -o freebsd https://git.FreeBSD.org/src.git /mnt/freebsd/usr/src
git clone -o freebsd https://git.FreeBSD.org/doc.git /mnt/freebsd/usr/doc
git clone -o freebsd https://git.FreeBSD.org/ports.git /mnt/freebsd/usr/ports
# list branches to build 
cd /mnt/freebsd/usr/src
git branch -r | grep stable
read -p 'Which version do you want to build? (number only)> ' VER
# switch to the selected branch
#
cd /mnt/freebsd/usr/src
git checkout stable/$VER
cd /mnt/freebsd/usr/doc
git checkout stable/$VER
cd /mnt/freebsd/usr/ports
git checkout stable/$VER
cd /mnt/freebsd/usr/src/release
mkdir /mnt/freebsd/release
# cross build start
cd /mnt/freebsd/usr/src/tools/build
MAKEOBJDIRPREFIX=/mnt/freebsd/release make.py -j $(nproc) TARGET=amd64 TARGET_ARCH=amd64 cleanworld
MAKEOBJDIRPREFIX=/mnt/freebsd/release make.py -j $(nproc) TARGET=amd64 TARGET_ARCH=amd64 buildworld
MAKEOBJDIRPREFIX=/mnt/freebsd/release make.py -j $(nproc) TARGET=amd64 TARGET_ARCH=amd64 buildkernel




