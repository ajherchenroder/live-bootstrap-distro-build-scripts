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
cd /
mkdir /mnt/netbsd/netbsd
cd /mnt/netbsd/netbsd
#list available versions
curl https://ftp.netbsd.org/pub/NetBSD/README -O
echo" The following Versions of NetBSD are available:"
cat README | grep NetBSD-
read -p 'select enter to continue> ' CONTINUE
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
./build.sh -U -u -m amd64 sourcesets
#build ISOs
./build.sh -U -u -m amd64 iso-image
./build.sh -U -u -m amd64 iso-image-sourceE
./build.sh -U -u -m amd64 install-image
./build.sh -U -u -m amd64 live-image
mkdir /mnt/netbsd/media
tar -czvf /mnt/netbsd/media/binary.tar.gz /mnt/netbsd/netbsd/usr/src/obj/releasedir/amd64/binary/
cp /mnt/netbsd/netbsd/usr/src/obj/releasedir/images/*.img.gz /mnt/netbsd/media
cp /mnt/netbsd/netbsd/usr/src/obj/releasedir/amd64/installation/cdrom/boot.iso /mnt/netbsd/media
gzip -d /mnt/netbsd/media/*.img.gz
echo "install media build is now complete. the results can be found at /mnt/netbsd/media."
echo "You will find three files in the directory. binary.tar.gz is an archive of all of the build packages."
echo "it can be used to update a system. boot.iso is a cd sized image that can be used to boot the system conjunction with"
echo "binary.tar.gz. The last file is NetBSD-(version)-amd64-install.img. This is the full install file that most users will"
echo "boot to install NetBSD."  