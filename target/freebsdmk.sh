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
cat > /mnt/freebsd/release.conf  << "EOF"
#!/bin/sh
#
## Set the directory within which the release will be built.
CHROOTDIR="/mnt/freebsd/release"
## Do not explicitly require the devel/git port to be installed.
NOGIT=1
## Set the version control system host.
GITROOT="https://git.freebsd.org/"
GITSRC="src.git"
GITPORTS="ports.git"
## Set the src/, ports/, and doc/ branches or tags.
SRCBRANCH="stable/$VER"
PORTBRANCH="stable/$VER"
## Set to override the default target architecture.
TARGET="amd64"
TARGET_ARCH="amd64"
KERNEL="GENERIC"
## Set to use world- and kernel-specific make(1) flags.
WORLD_FLAGS="-j $(nproc) "
KERNEL_FLAGS="-j $(nproc)"
## Set miscellaneous 'make release' settings.
#NOPORTS=
#NOSRC=
WITH_DVD=1
WITH_COMPRESSED_IMAGES=1
## Set to '1' to disable multi-threaded xz(1) compression.
XZ_THREADS=1
EOF
#start the build
/bin/sh /mnt/freebsd/usr/src/release/release.sh -c /mnt/freebsd/release.conf






