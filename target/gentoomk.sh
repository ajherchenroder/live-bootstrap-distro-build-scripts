#! /bin/bash
#set up working directory
#
#Notes:
#Live bootstrap doesn't have the lsblk command, using fdisk -l to enumerated the drives.
#You need to be root to run this script
#
#decide where we are going to put things
echo "This script can make a stage 3 and snapshot tarball or setup and install Gentoo on another drive."
read -p 'enter 1 for stage 3/snapshot or 2 for full install (default is stage 3/snapshot > ' FULLBUILD
mkdir /mnt/gentoo
fdisk -l | grep /dev
read -p 'Select the disk /dev node to build gentoo on. (sdxx) > ' DISKTOUSE
mount /dev/$DISKTOUSE /mnt/gentoo
if FULLBUILD==1 ; then
   read -p 'Select the disk /dev node to install the final gentoo on. (sdx) > ' DISKTOUSE2
fi
#download gentoo files
mkdir /gentoosources
cd /gentoosources
#local
curl http://192.168.2.102/gentoo/gentoo-current.xz.sqfs -O -L
curl http://192.168.2.102/gentoo/portage-3.0.65.tar.bz2 -O -L

#curl http://distfiles.gentoo.org/snapshots/squashfs/gentoo-current.xz.sqfs -O -L
#curl https://gitweb.gentoo.org/proj/portage.git/snapshot/portage-3.0.65.tar.bz2 -O -L
## Symlink python (needed for portage)
ln -sv python3 /usr/bin/python

# Install portage
tar -xvf portage-3.0.65.tar.bz2
cd portage-3.0.65
meson setup --prefix /usr build
meson install -C build

# Configure portage
mkdir /mnt/tmp
mkdir -p /var/db/repos/gentoo
mount /gentoosources/gentoo-*.sqfs /mnt/tmp
cp -avT /mnt/tmp /var/db/repos/gentoo
umount /mnt/tmp
rm -Rf /mnt/tmp

# Set up passswd and group for portage
echo 'portage:x:250:250:portage:/var/tmp/portage:/bin/false' >> /etc/passwd
echo 'portage::250:portage' >> /etc/group

#network and locale stuff
echo 'nameserver 192.168.2.3' > /etc/resolv.conf
#echo 'nameserver 1.1.1.1' > /etc/resolv.conf
echo 'C.UTF-8 UTF-8' > /etc/locale.gen

#make.conf
cat > /etc/portage/make.conf << 'EOF'
FEATURES='-news -pid-sandbox'
CONFIG_PROTECT='-* /etc/locale.gen'
USE='-nls'
EOF

##package.use.force
#cat > /etc/portage/profile/package.use.force << 'EOF'
#sys-devel/gcc -cxx
#EOF

#profile (set to ver 23)
#mkdir -p /etc/portage/profile
#ln -svr /var/db/repos/gentoo/profiles/default/linux/amd64/23.0 /etc/portage/make.profile

# Install baselayout
#emerge -O1 sys-apps/baselayout
#source /etc/profile

# Run bootstrap.sh
/var/db/repos/gentoo/scripts/bootstrap.sh
