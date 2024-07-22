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
USE=-pam /gentoo/prefix/usr/bin/emerge -1 sys-libs/libcap
USE=-http2 /gentoo/prefix/usr/bin/emerge -1 net-misc/curl
/gentoo/prefix/usr/bin/emerge -l sys-apps/locale-gen
echo "en_US.UTF-8 UTF-8" >> /gentoo/prefix/etc/locale.gen
/gentoo/prefix/usr/sbin/locale-gen

#set up environment
export EPREFIX="/"

# Rebuild and install everything into a new root, completely cleaning out LFS
USE="build -split-usr" /gentoo/prefix/usr/bin/emerge --root /mnt/gentoo sys-apps/baselayout


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
USE="-lzma" EXTRA_ECONF=--disable-bootstrap   /gentoo/prefix/usr/bin/emerge --root /mnt/gentoo sys-devel/gcc
/gentoo/prefix/usr/bin/emerge --root /mnt/gentoo -1 sys-libs/libcap
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

read -p 'post partition build trap1> ' BOOTSTRAPPED