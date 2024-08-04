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


#install dependencies
source /gentoo/prefix/etc/profile

/gentoo/prefix/usr/bin/emerge sys-kernel/gentoo-sources
cd /gentoo/prefix/usr/src/linux*
make mrproper
make defconfig
ln -s /gentoo/prefix/usr/src/linux* /gentoo/prefix/usr/src/linux
USE=-pam /gentoo/prefix/usr/bin/emerge -1 sys-libs/libcap
USE=-http2 /gentoo/prefix/usr/bin/emerge -1 net-misc/curl
/gentoo/prefix/usr/bin/emerge nano
/gentoo/prefix/usr/bin/emerge less
#USE="xattr" /gentoo/prefix/usr/bin/emerge sys-apps/coreutils
/gentoo/prefix/usr/bin/emerge -1 sys-apps/util-linux
/gentoo/prefix/usr/bin/emerge -l sys-apps/locale-gen
/gentoo/prefix/usr/bin/emerge app-arch/zstd
/gentoo/prefix/usr/bin/emerge sys-libs/libxcrypt
/gentoo/prefix/usr/bin/emerge -1 sys-apps/util-linux
/gentoo/prefix/usr/bin/emerge sys-apps/systemd-utils
/gentoo/prefix/usr/bin/emerge --deep -n @system
EPREFIX="/" USE="-pam" /gentoo/prefix/usr/bin/emerge --root=/ sys-libs/libcap

#move some files to trick pkg-config
#cp -r /gentoo/prefix/usr/include/libmount /usr/include/


echo "en_US.UTF-8 UTF-8" >> /gentoo/prefix/etc/locale.gen
/gentoo/prefix/usr/sbin/locale-gen
eselect locale set 4
. /gentoo/prefix/etc/profile

#set up environment by removing the eeprefix
export EPREFIX="/"

#create base layout
USE="build -split-usr" /gentoo/prefix/usr/bin/emerge --root /mnt/gentoo sys-apps/baselayout

#more env setup
#
#make a working profile.env
rm /mnt/gentoo/etc/profile.env
#working
cat > /mnt/gentoo/etc/profile.env << 'EOF'
export CONFIG_PROTECT_MASK='/mnt/gentoo/etc/gentoo-release'
export INFOPATH='/mnt/gentoo/usr/share/info'
export MANPATH='/mnt/gentoo/usr/local/share/man:/mnt/gentoo/usr/share/man'
export PATH='/mnt/gentoo/usr/local/sbin:/mnt/gentoo/usr/local/bin:/mnt/gentoo/usr/sbin:/mnt/gentoo/usr/bin:/mnt/gentoo/sbin:/mnt/gentoo/bin:/mnt/gentoo/opt/bin:/gentoo/prefix/usr/local/sbin:/gentoo/prefix/usr/local/bin:/gentoo/prefix/usr/sbin:/gentoo/prefix/usr/bin:/gentoo/prefix/sbin:/gentoo/prefix/bin:/gentoo/prefix/opt/bin'
EOF
source /mnt/gentoo/etc/profile

#make.conf
mkdir /mnt/gentoo/etc/portage
#
#working
cat > /mnt/gentoo/etc/portage/make.conf << 'EOF'
USE="unicode nls"
CFLAGS="${CFLAGS} -O2 -pipe"
CXXFLAGS="${CFLAGS}"
MAKEOPTS="-j2"
CONFIG_SHELL="/gentoo/prefix/bin/bash"
DISTDIR="/mnt/gentoo/var/cache/distfiles"
# sandbox does not work well on Prefix, bug #490246
FEATURES="${FEATURES} -usersandbox -sandbox"
ACCEPT_KEYWORDS="${ARCH} -~${ARCH}"
EOF
#
## copy over the dist files from the prefix to speed thing up
mkdir /mnt/gentoo/var/cache/distfiles
cp /gentoo/prefix/var/cache/distfiles/* /mnt/gentoo/var/cache/distfiles
mkdir /mnt/gentoo/var/db/repos/
cp -r /gentoo/prefix/var/db/repos/* /mnt/gentoo/var/db/repos/
#
## copy locale files from the prefix
cp /gentoo/prefix/etc/env.d/02locale /mnt/gentoo/etc/env.d
source /mnt/gentoo/etc/profile


#circular dependency resolution
ln -s /gentoo/prefix/usr/src/linux /mnt/gentoo/usr/src/linux
EPREFIX="/" EXTRA_ECONF=--disable-bootstrap   /gentoo/prefix/usr/bin/emerge --root=/mnt/gentoo sys-devel/gcc
EPREFIX="/" /gentoo/prefix/usr/bin/emerge -1 --root=/mnt/gentoo sys-libs/libxcrypt
EPREFIX="/" /gentoo/prefix/usr/bin/emerge -1 --root=/mnt/gentoo sys-apps/util-linux
EPREFIX="/" USE="-pam" /gentoo/prefix/usr/bin/emerge --root=/mnt/gentoo sys-libs/libcap
EPREFIX="/" USE="-split-usr -boot -kernel-install -kmod udev -test" /gentoo/prefix/usr/bin/emerge --root=/mnt/gentoo  sys-apps/systemd-utils
source /mnt/gentoo/etc/profile
EPREFIX="/" USE="-lzma"  /gentoo/prefix/usr/bin/emerge --root=/mnt/gentoo  @system
source /mnt/gentoo/etc/profile
USE="-lzma" EXTRA_ECONF=--disable-bootstrap   /gentoo/prefix/usr/bin/emerge --root=/mnt/gentoo sys-devel/gcc
EPREFIX="/" USE="-lzma"  /gentoo/prefix/usr/bin/emerge --root=/mnt/gentoo -n @system
EPREFIX="/" USE="-lzma"  /gentoo/prefix/usr/bin/emerge --root=/mnt/gentoo -n @system
EPREFIX="/" USE="-lzma"  /gentoo/prefix/usr/bin/emerge --root=/mnt/gentoo -n @system

#reconfigure files for run outside the prefix 
rm -Rf /mnt/gentoo/etc/portage/make.conf
#
#make.conf final
cat > /mnt/gentoo/etc/portage/make.conf << 'EOF'
USE="unicode nls"
CFLAGS="${CFLAGS} -O2 -pipe"
CXXFLAGS="${CFLAGS}"
MAKEOPTS="-j2"
CONFIG_SHELL="/bin/bash"
DISTDIR="/var/cache/distfiles"
# sandbox does not work well on Prefix, bug #490246
FEATURES="${FEATURES} -usersandbox -sandbox"
ACCEPT_KEYWORDS="${ARCH} -~${ARCH}"
EOF

#all done drop back to the main build
read -p 'post partition build trap1> ' BOOTSTRAPPED
exit 0








#backup material 




#download gentoo files
mkdir /mnt/gentoo/gentoosources
cd /mnt/gentoo/gentoosources
#local
curl http://192.168.2.102/gentoo/portage-latest.tar.bz2 -O -L

#curl http://distfiles.gentoo.org/snapshots/portage-latest.tar.bz2 -O -L

cd /mnt/gentoo/gentoosources
tar -xpf portage-latest.tar.bz2
cd portage
mkdir -p /mnt/gentoo/var/db/repos/gentoo
cp -avT /mnt/gentoo/gentoosources/portage /mnt/gentoo/var/db/repos/gentoo

#set up environment continued
export ROOT="/mnt/gentoo"
export SYSROOT="/mnt/gentoo"
export PORTAGE_LOGDIR="/mnt/gentoo/var/log"
export FEATURES="-news -pid-sandbox"
export MAKEOPTS="-j2"
echo "en_US.UTF-8 UTF-8" >> /gentoo/prefix/etc/locale.gen
touch /gentoo/prefix/etc/env.d/02locale
echo "LANG="en_US.UTF-8"" >> /gentoo/prefix/etc/env.d/02locale
echo "LC_COLLATE="C.UTF-8"" >> /gentoo/prefix/etc/env.d/02locale
cp /gentoo/prefix/etc/env.d/02locale /mnt/gentoo/etc/env.d/02locale
USE="-lzma" EXTRA_ECONF=--disable-bootstrap   /gentoo/prefix/usr/bin/emerge --root=/mnt/gentoo sys-devel/gcc
/gentoo/prefix/usr/bin/emerge --root=/mnt/gentoo -1 sys-libs/libcap
source /etc/profile
#BOOTSTRAPPED="n"
#while [[ "$BOOTSTRAPPED" == "n" ]];
#do
   USE="-lzma"  /gentoo/prefix/usr/bin/emerge --root=/mnt/gentoo -n @system
   #read -p 'Did the @system build complete successfully? (y or n)> ' BOOTSTRAPPED
   #if [ "$BOOTSTRAPPED" == "y" ]; then
     # break 
   #fi
#done
/gentoo/prefix/usr/bin/emerge -l --root=/mnt/gentoo sys-apps/locale-gen
/gentoo/prefix/usr/bin/emerge --root=/mnt/gentoo -n sys-libs/libcap
USE="-lzma"  /gentoo/prefix/usr/bin/emerge --root=/mnt/gentoo -n @system
source /etc/profile
/gentoo/prefix/usr/bin/emerge --root /mnt/gentoo -n sys-libs/libcap
USE="-lzma"  /gentoo/prefix/usr/bin/emerge --root=/mnt/gentoo -n @system
source /etc/profile
/gentoo/prefix/usr/bin/emerge -n --root /mnt/gentoo sys-apps/locale-gen
USE="-lzma"  /gentoo/prefix/usr/bin/emerge --root=/mnt/gentoo -n @system
source /etc/profile
#clean up and prep for packaging
/gentoo/prefix/usr/bin/emerge -l --root=/mnt/gentoo sys-apps/locale-gen
mkdir /mnt/gentoo/etc/portage


* The following users have non-existent shells!
 * adm - /gentoo/prefix/bin/false
 * bin - /gentoo/prefix/bin/false
 * daemon - /gentoo/prefix/bin/false
 * halt - /gentoo/prefix/sbin/halt
 * lp - /gentoo/prefix/bin/false
 * news - /gentoo/prefix/bin/false
 * nobody - /gentoo/prefix/bin/false
 * operator - /gentoo/prefix/sbin/nologin
 * portage - /gentoo/prefix/bin/false
 * root - /gentoo/prefix/bin/bash
 * shutdown - /gentoo/prefix/sbin/shutdown
 * sync - /gentoo/prefix/bin/sync
 * uucp - /gentoo/prefix/bin/false

#working
cat > /mnt/gentoo/etc/profile.env << 'EOF'
export CONFIG_PROTECT_MASK='/mnt/gentoo/etc/gentoo-release'
export INFOPATH='/mnt/gentoo/usr/share/info'
export MANPATH='/mnt/gentoo/usr/local/share/man:/mnt/gentoo/usr/share/man'
export PATH='/mnt/gentoo/usr/local/sbin:/mnt/gentoo/usr/local/bin:/mnt/gentoo/usr/sbin:/mnt/gentoo/usr/bin:/mnt/gentoo/sbin:/mnt/gentoo/bin:/mnt/gentoo/opt/bin:/gentoo/prefix/usr/local/sbin:/gentoo/prefix/usr/local/bin:/gentoo/prefix/usr/sbin:/gentoo/prefix/usr/bin:/gentoo/prefix/sbin:/gentoo/prefix/bin:/gentoo/prefix/opt/bin'
EOF

#final
cat > /mnt/gentoo/etc/profile.env << 'EOF'
export CONFIG_PROTECT_MASK='/etc/gentoo-release'
export INFOPATH='/usr/share/info'
export MANPATH='/usr/local/share/man:/usr/share/man'
export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/bin'
export ROOTPATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/bin'
EOF

