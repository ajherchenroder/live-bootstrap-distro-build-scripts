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
MAKEOPTS="-j2"
EMERGE_DEFAULT_OPTS="--jobs 1"
CONFIG_PROTECT='-* /etc/locale.gen'
CFLAGS="-march=x86-64 -pipe"
CXXFLAGS="${CFLAGS}"
USE='-nls ABI_86="64"'

EOF

##package.use.force
cat > /etc/portage/profile/package.use.force << 'EOF'
sys-devel/gcc -cxx
EOF


#profile (set to ver 23)
mkdir -p /etc/portage/profile
ln -svr /var/db/repos/gentoo/profiles/default/linux/amd64/23.0 /etc/portage/make.profile

#Presetup pkgs
emerge -O1 net-misc/wget
PYTHON_COMPAT_OVERRIDE=python3_11 emerge -O1 app-misc/ca-certificates
emerge -O1 dev-build/automake
emerge -O1 dev-build/autoconf
USE=-acl emerge -O1 net-misc/rsync

#clear logs
rm -rf /var/lib/portage /var/db/pkg /var/cache/edb /var/log/emerge.log /var/log/portage

##break xz dependency issue by telling portage about the xztools we install with lfs
#cat > /etc/portage/profile/package.provided << 'EOF'
#app-arch/xz-utils-5.4.4
#app-alternatives/ninja-1.11.1
#sys-devel/gettext-0.22
#sys-devel/bison-3.8.2
#sys-devel/flex-2.6.4
#app-arch/bzip2-1.08
#sys-apps/gawk-5.2.2
#app-arch/tar-1.35
#app-arch/gzip-1.12
#app-alternatives/gzip-1
#app-alternatives/awk-4
#sys-libs/libxcrypt--4.4.36 
#EOF

# Install baselayout
emerge -O1 sys-apps/baselayout
source /etc/profile
# Break dependency cycles

#rebuild tool chain
#support files
emerge -O1 sys-apps/gentoo-functions
emerge -O1 app-portage/elt-patches 
emerge -O1 sys-devel/gnuconfig

#headers
CTARGET=x86_64-bootstrap-linux-gnu USE=headers-only emerge -O1 sys-kernel/linux-headers
CTARGET=x86_64-bootstrap-linux-gnu USE=headers-only PYTHON_COMPAT_OVERRIDE=python3_11 emerge -O1 sys-libs/glibc
read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED

gentoo cross compiler

emerge -O1 dev-libs/gmp 
emerge -O1 dev-libs/mpfr
emerge -O1 dev-libs/mpc
emerge -O1 sys-devel/binutils-config 
emerge -O1 sys-devel/gcc-config
CTARGET=x86_64-bootstrap-linux-gnu emerge -O1 sys-devel/binutils
CTARGET=x86_64-bootstrap-linux-gnu EXTRA_ECONF=--with-sysroot=/usr/$CTARGET EXTRA_EMAKE='MAKE=make MAKE+=libsuffix=../lib64' USE='-sanitize -openmp -fortran -cxx' emerge -O1 sys-devel/gcc
CTARGET=x86_64-bootstrap-linux-gnu CFLAGS_x86=-m32 PYTHON_COMPAT_OVERRIDE=python3_11 emerge -O1 sys-libs/glibc
CTARGET=x86_64-bootstrap-linux-gnu EXTRA_ECONF='--with-sysroot=/usr/$CTARGET --enable-shared' EXTRA_EMAKE='MAKE=make MAKE+=libsuffix=../lib64' USE='-sanitize -openmp -fortran' emerge -O1 sys-devel/gcc
read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED

#install final glibc 
/usr/x86_64-bootstrap-linux-gnu/lib64/ld-linux-x86-64.so.2 /usr/x86_64-bootstrap-linux-gnu/sbin/ldconfig
rm /usr/x86_64-bootstrap-linux-gnu/usr/lib/crti.o 
CC=x86_64-bootstrap-linux-gnu-gcc CXX=x86_64-bootstrap-linux-gnu-g++ CFLAGS_x86=-m32 PYTHON_COMPAT_OVERRIDE=python3_11 emerge -O1 sys-libs/glibc

# Install final compiler
CC='x86_64-bootstrap-linux-gnu-gcc --sysroot=/' CXX='x86_64-bootstrap-linux-gnu-g++ --sysroot=/' emerge -O1 sys-kernel/linux-headers
CC='x86_64-bootstrap-linux-gnu-gcc --sysroot=/' CXX='x86_64-bootstrap-linux-gnu-g++ --sysroot=/' EXTRA_ECONF=--disable-bootstrap USE='-sanitize -openmp -fortran' emerge -O1 sys-devel/gcc
emerge -O1 sys-devel/binutils
read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED

# Set up python-exec
# changed to a one shot because of circular dependencies 
mkdir -p /usr/lib/python-exec/python3.11
ln -sv python3 /usr/lib/python-exec/python3.11/python
ln -svr /usr/bin/python3.11 /usr/lib/python-exec/python3.11/python3
emerge --oneshot -O1 dev-lang/python-exec
#read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED

source /etc/profile
# Break dependency cycles
emerge -O1 app-alternatives/ninja
#read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED 
emerge -O1 app-alternatives/yacc
#read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED 
emerge -O1 app-alternatives/lex 
#read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED
emerge -O1 app-alternatives/bzip2
#read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED
emerge -O1 app-alternatives/gzip
#read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED 
emerge -O1 app-alternatives/tar
#read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED 
emerge -O1 app-alternatives/awk
#read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED
emerge -O1 sys-libs/libxcrypt
read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED

#Install them again because they tend to break
emerge -O1 dev-lang/python-exec
emerge -O1 app-alternatives/ninja
emerge -O1 app-alternatives/yacc
emerge -O1 app-alternatives/lex 
emerge -O1 app-alternatives/bzip2
emerge -O1 app-alternatives/gzip
emerge -O1 app-alternatives/tar
emerge -O1 app-alternatives/awk
emerge -O1 sys-libs/libxcrypt
read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED

# third time is the charm
emerge -O1 dev-lang/python-exec
emerge -O1 app-alternatives/ninja
emerge -O1 app-alternatives/yacc
emerge -O1 app-alternatives/lex 
emerge -O1 app-alternatives/bzip2
emerge -O1 app-alternatives/gzip
emerge -O1 app-alternatives/tar
emerge -O1 app-alternatives/awk
emerge -O1 sys-libs/libxcrypt
read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED

# Install implicit build dependencies
emerge -O1 dev-build/meson-format-array
read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED
emerge -O1 app-misc/pax-utils
read -p 'Did the last step complete successfully? (y or n)> ' BOOTSTRAPPED


# Run bootstrap.sh
#BOOTSTRAPPED=n
echo "the Gentoo bootstrap script may require multiple runs to complete"
#while [BOOTSTRAPPED=="n"];
#do
/var/db/repos/gentoo/scripts/bootstrap.sh
read -p 'Did the bootstrap complete successfully? (y or n)> ' BOOTSTRAPPED
#done

# Install the rest of @system
USE="openmp" emerge -1N sys-devel/gcc  # Install with USE="openmp"
read -p 'Did the bootstrap complete successfully? (y or n)> ' BOOTSTRAPPED
USE=-pam emerge -1 sys-libs/libcap
read -p 'Did the bootstrap complete successfully? (y or n)> ' BOOTSTRAPPED
USE=-http2 emerge -1 net-misc/curl
read -p 'Did the bootstrap complete successfully? (y or n)> ' BOOTSTRAPPED
emerge -1 sys-apps/shadow  # required by everything in acct-user and acct-group
read -p 'Did the bootstrap complete successfully? (y or n)> ' BOOTSTRAPPED
emerge -DN @system
read -p 'Did the bootstrap complete successfully? (y or n)> ' BOOTSTRAPPED

# Rebuild and install everything into a new root, completely cleaning out LFS
USE=build emerge --root /mnt/gentoo sys-apps/baselayout
read -p 'Did the bootstrap complete successfully? (y or n)> ' BOOTSTRAPPED
emerge --root /mnt/gentoo @system
read -p 'Did the bootstrap complete successfully? (y or n)> ' BOOTSTRAPPED

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