#! /bin/bash
#set up working directory
#
#Notes:
#Live bootstrap doesn't have the lsblk command, using fdisk -l to enumerated the drives.
#The netbsd build process uses the /mnt/netbsd and /tmp directories. This script will create and mount them in the working disk. 
#You need to be root to run this script

mkdir /mnt/netbsd
fdisk -l | grep /dev
read -p 'Select the disk /dev node to build netbsd on. (sdxx) > ' DISKTOUSE
mount /dev/$DISKTOUSE /mnt/netbsd
#rm -Rf /mnt/netbsd/tmp
#mkdir /mnt/netbsd/tmp
cd /
#ln -s /mnt/netbsd/tmp /tmp
#rm -Rf /mnt/netbsd/netbsd
mkdir /mnt/netbsd/netbsd
cd /mnt/netbsd/netbsd
#download sources using curl
#curl  ftp://ftp.netbsd.org/pub/NetBSD/NetBSD-9.3/source/sets/gnusrc.tgz -O
#local
curl http://192.168.2.102/netbsd/gnusrc.tgz -O
#curl  ftp://ftp.netbsd.org/pub/NetBSD/NetBSD-9.3/source/sets/sharesrc.tgz -O
#local
curl http://192.168.2.102/netbsd/sharesrc.tgz -O
#curl  ftp://ftp.netbsd.org/pub/NetBSD/NetBSD-9.3/source/sets/src.tgz -O
#local
curl http://192.168.2.102/netbsd/src.tgz -O
#curl  ftp://ftp.netbsd.org/pub/NetBSD/NetBSD-9.3/source/sets/syssrc.tgz -O 
#local
curl http://192.168.2.102/netbsd/syssrc.tgz -O
#curl ftp://ftp.netbsd.org/pub/NetBSD/NetBSD-9.3/source/sets/xsrc.tgz -O
#local
curl http://192.168.2.102/netbsd/xsrc.tgz -O
#untar the sources and run them through gzip
gzip -d  *.tgz
tar -xvf /mnt/netbsd/netbsd/gnusrc.tar
tar -xvf /mnt/netbsd/netbsd/sharesrc.tar
tar -xvf /mnt/netbsd/netbsd/src.tar
tar -xvf /mnt/netbsd/netbsd/syssrc.tar
tar -xvf /mnt/netbsd/netbsd/xsrc.tar
rm -Rf /mnt/netbsd/netbsd/*.tar
#build cross compiler
cd /mnt/netbsd/netbsd/usr/src
#clean up the environment from any prior runs
./build.sh -U -m amd64 cleandir
# start the actual build
./build.sh -U -m amd64 tools
#read -p 'select enter to continue> ' CONTINUE
#build netbsd itself
./build.sh -U -u -m amd64 -x release
#read -p 'select enter to continue> ' CONTINUE
./build.sh -U -u -m amd64 sourcesets
#read -p 'select enter to continue> ' CONTINUE
#build ISOs
./build.sh -U -u -m amd64 iso-image
#read -p 'select enter to continue> ' CONTINUE
./build.sh -U -u -m amd64 iso-image-source
#read -p 'select enter to continue> ' CONTINUE
./build.sh -U -u -m amd64 install-image
#read -p 'select enter to continue> ' CONTINUE
./build.sh -U -u -m amd64 live-image
#read -p 'select enter to continue> ' CONTINUE
mkdir /mnt/netbsd/media
tar -czvf /mnt/netbsd/media/binary.tar.gz /mnt/netbsd/netbsd/usr/src/obj/releasedir/amd64/binary/
cp /mnt/netbsd/netbsd/usr/src/obj/releasedir/images/NetBSD-9.3-amd64-install.img.gz /mnt/netbsd/media
cp /mnt/netbsd/netbsd/usr/src/obj/releasedir/amd64/installation/cdrom/boot.iso /mnt/netbsd/media