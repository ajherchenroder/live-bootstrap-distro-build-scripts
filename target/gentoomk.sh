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
if [FULLBUILD==2] ; then
   read -p 'Select the disk /dev node to install the final gentoo on. (sdx) > ' DISKTOUSE2
fi
#download gentoo files
mkdir /gentoosources
cd /gentoosources
#local
curl http://192.168.2.102/gentoo/portage-latest.tar.bz2 -O -L
curl http://192.168.2.102/gentoo/portage-3.0.65.tar.bz2 -O -L

#curl http://distfiles.gentoo.org/snapshots/portage-latest.tar.bz2 -O -L
#curl https://gitweb.gentoo.org/proj/portage.git/snapshot/portage-3.0.65.tar.bz2 -O -L
## Symlink python (needed for portage)
ln -sv python3 /usr/bin/python
#
# Install portage
tar -xvf portage-3.0.65.tar.bz2
cd portage-3.0.65
meson setup --prefix /usr build
meson install -C build
cd /gentoosources
rm -Rf portage-3.0.65
#
# Configure portage
tar -xpf portage-latest.tar.bz2
cd portage
mkdir -p /var/db/repos/gentoo
cp -avT /gentoosources/portage /var/db/repos/gentoo

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
USE='-nls ABI_86="64"'
EOF

##package.use.force
#cat > /etc/portage/profile/package.use.force << 'EOF'
#sys-devel/gcc -cxx
#EOF


#profile (set to ver 23)
mkdir -p /etc/portage/profile
ln -svr /var/db/repos/gentoo/profiles/default/linux/amd64/23.0 /etc/portage/make.profile

##break xz dependency issue by telling portage about the xztools we install with lfs
cat > /etc/portage/profile/package.provided << 'EOF'
app-arch/xz-utils-5.4.4
app-alternatives/ninja-1.11.1
sys-devel/gettext-0.22
sys-devel/bison-3.8.2
sys-devel/flex-2.6.4
app-arch/bzip2-1.08
sys-apps/gawk-5.2.2
app-arch/tar-1.35
app-arch/gzip-1.12
app-alternatives/gzip-1
app-alternatives/awk
sys-libs/libxcrypt--4.4.36 
EOF

# Install baselayout
emerge -O1 sys-apps/baselayout
source /etc/profile
read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED

# Break dependency cycles


# Install implicit build dependencies
emerge -O1 dev-build/meson-format-array
read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED
emerge -O1 app-misc/pax-utils

# Run bootstrap.sh
#BOOTSTRAPPED=n
echo "the Gentoo bootstrap script may require multiple runs to complete"
#while [BOOTSTRAPPED=="n"];
#do
/var/db/repos/gentoo/scripts/bootstrap.sh
read -p 'Did the bootstrap complete successfully? (y or n)> ' BOOTSTRAPPED
#done

# Install the rest of @system
emerge -1N sys-devel/gcc  # Install with USE="openmp"
USE=-pam emerge -1 sys-libs/libcap
USE=-http2 emerge -1 net-misc/curl
emerge -1 sys-apps/shadow  # required by everything in acct-user and acct-group
emerge -DN @system

# Rebuild and install everything into a new root, completely cleaning out LFS
USE=build emerge --root /mnt/gentoo sys-apps/baselayout
emerge --root /mnt/gentoo @system

# Pack it up

tar cf /gentoo-bootstrap.tar -C /mnt/gentoo .
xz -9v /gentoo-bootstrap.tar
mkdir /mnt/gentoo/release
cp /gentoo-bootstrap.tar.xz /mnt/gentoo/release
# stop if only building a stage 3

if [FULLBUILD==1] ; then
   echo "The Gentoo bootstrap stage 3 is located in /mnt/gentoo/release"
   exit 0
fi

#Create gentoo chroot

echo "Building the Gentoo Chroot"