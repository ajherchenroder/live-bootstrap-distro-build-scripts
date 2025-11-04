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
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mount -t devpts devpts /dev/pts
mount -t tmpfs -o nosuid,nodev tmpfs /dev/shm 
source /steps/env

while getopts L flag; 
do
     case "${flag}" in
        L) REMOTE="local";; #download from the local repositories
     esac
done
mkdir -p /var/cache/distfiles; cd /var/cache/distfiles
if test "$REMOTE" = "local"; then 
   echo "local"
   curl -LO http://192.168.2.102/gentoo/portage-3.0.69.3.tar.gz
   #curl -LO http://192.168.2.102/gentoo/gentoo-20250101.xz.sqfs
   curl -LO http://distfiles.gentoo.org/snapshots/squashfs/gentoo-20251028.xz.sqfs
   curl -LO http://192.168.2.102/gentoo/squashfs-tools-4.6.1.tar.gz
else
   echo "remote"
#curl -LO http://gitweb.gentoo.org/proj/portage.git/snapshot/portage-3.0.65.tar.bz2
#curl -LO http://distfiles.gentoo.org/snapshots/squashfs/gentoo-20240801.xz.sqfs
  curl -LO http://gitweb.gentoo.org/proj/portage.git/snapshot/portage-3.0.69.3.tar.gz
#curl -LO http://distfiles.gentoo.org/snapshots/squashfs/gentoo-20250109.xz.sqfs
  curl -LO http://distfiles.gentoo.org/snapshots/squashfs/gentoo-20251028.xz.sqfs
  curl -LO https://github.com/plougher/squashfs-tools/archive/refs/tags/4.6.1/squashfs-tools-4.6.1.tar.gz
fi

# Build squashfs-tools to extract the ::gentoo tree
tar xf /var/cache/distfiles/squashfs-tools-4.6.1.tar.gz
cd squashfs-tools-4.6.1
make -C squashfs-tools install \
    INSTALL_PREFIX=/usr \
    XZ_SUPPORT=1
cd ..
rm -rf squashfs-tools-4.6.1

# Unpack the ::gentoo tree
#unsquashfs /var/cache/distfiles/gentoo-20250109.xz.sqfs
unsquashfs /var/cache/distfiles/gentoo-20251028.xz.sqfs
mkdir -p /var/db/repos
rm -rf /var/db/repos/gentoo
mv squashfs-root /var/db/repos/gentoo

# Install temporary copy of portage
tar xf /var/cache/distfiles/portage-3.0.69.3.tar.gz
cd portage-3.0.69.3
#patch -p1 -i ../portage.patch 
cd ..
ln -sf portage-3.0.69.3 portage 

# Add portage user/group
echo 'portage:x:250:250:portage:/var/tmp/portage:/bin/false' >> /etc/passwd
echo 'portage::250:portage' >> /etc/group

# Configure portage
mkdir -p /etc/portage/make.profile
cat > /etc/portage/make.profile/make.defaults << 'EOF'
FETCHCOMMAND="curl -k --retry 3 -m 60 --ftp-pasv -o \"\${DISTDIR}/\${FILE}\" -L \"\${URI}\""
RESUMECOMMAND="curl -C - -k --retry 3 -m 60 --ftp-pasv -o \"\${DISTDIR}/\${FILE}\" -L \"\${URI}\""
FEATURES="-news -sandbox -usersandbox -pid-sandbox -parallel-fetch"
BINPKG_COMPRESS="bzip2"
ARCH="amd64"
ABI="$ARCH"
DEFAULT_ABI="$ARCH"
ACCEPT_KEYWORDS="$ARCH"
CHOST="amd64-lfs-linux-gnu"
LIBDIR_x86="lib/$CHOST"
PKG_CONFIG_PATH="/usr/lib/$CHOST/pkgconfig"
IUSE_IMPLICIT="kernel_linux prefix prefix-guest elibc_glibc"
IUSE_IMPLICIT="$IUSE_IMPLICIT x86 amd64 elibc_musl"  # dev-libs/gmp
IUSE_IMPLICIT="$IUSE_IMPLICIT sparc riscv m68k alpha "  # sys-libs/zlib and ldev-libs/ibgcryp
USE_EXPAND="PYTHON_TARGETS PYTHON_SINGLE_TARGET"
USE="kernel_linux build pam"
SKIP_KERNEL_CHECK=y  # linux-info.eclass
EOF
mkdir /etc/portage/package.use
cat > /etc/portage/package.use/files << 'EOF'
dev-lang/python -ensurepip -ncurses -readline -sqlite -ssl
EOF
grep '^PYTHON_TARGETS=\|^PYTHON_SINGLE_TARGET=' \
    /var/db/repos/gentoo/profiles/base/make.defaults \
    >> /etc/portage/make.profile/make.defaults

cat > /etc/portage/package.unmask << 'EOF'
*/*
EOF

mkdir /etc/portage/package.mask
cat > /etc/portage/package.mask/files << 'EOF'
EOF

mkdir /etc/portage/profile
cat > /etc/portage/profile/package.provided << 'EOF'
acct-user/portage-0
#app-alternatives/awk-0
app-alternatives/gzip-0
app-alternatives/lex-0
app-alternatives/yacc-0
app-arch/tar-1.27
app-arch/xz-utils-5.8.1-r1
app-arch/zstd-0
#app-crypt/libb2-0
app-crypt/libbz2-0
#dev-build/autoconf-archive-0
#dev-build/libtool-2.4.7-r3
dev-lang/perl-5.38.2-r3
dev-libs/libffi-0
dev-libs/popt-1.5
dev-python/platformdirs-4.2.2
dev-python/setuptools-scm-0
dev-python/trove-classifiers-2024.10.16
dev-util/re2c-0
sys-apps/coreutils-9.7
sys-apps/baselayout-2.9
sys-apps/help2man-0
sys-apps/locale-gen-0
sys-apps/sandbox-2.2
sys-apps/sed-4.0.5
sys-apps/texinfo-7.1
sys-apps/util-linux-0
sys-devel/binutils-2.27
sys-devel/bison-3.5.4
sys-devel/flex-2.5.4
sys-devel/gcc-6.2
sys-devel/gettext-0
sys-devel/m4-1.4.16
sys-devel/patch-0
sys-libs/zlib-1.2.12
virtual/libcrypt-0
virtual/libintl-0
EOF

# Turn /bin/bzip2 into a symlink to avoid failures in app-arch/bzip2
if [ ! -h /bin/bzip2 ]; then
    mv /bin/bzip2 /bin/bzip2-reference
    ln -s bzip2-reference /bin/bzip2
fi
# Turn /bin/lzip into a symlink to avoid failures in app-arch/lzip
if [ ! -h /bin/lzip ]; then
    mv /bin/lzip /bin/lzip-reference
    ln -s lzip-reference /bin/lzip
fi
# add a gtar symlink if required 
if [ ! -h /bin/gtar ]; then
    ln -s /bin/tar /bin/gtar
fi

#symlink existing GCC to amd64-lfs-linux-gnu-cc
ln -s /bin/gcc /bin/amd64-lfs-linux-gnu-cc


# For some reason, make hangs when used in parallel, rebuild it first.
MAKEOPTS=-j1 ./portage/bin/emerge -D1n app-arch/lzip dev-build/make 

# Upgrade python and install portage
FEATURES="-collision-detect"  ./portage/bin/emerge -Dn sys-apps/portage
FEATURES="-collision-detect"  ./portage/bin/emerge -D sys-apps/portage

# Install BDEPENDs for cross-toolchain
emerge -D1n sys-devel/binutils-config  # sys-devel/binutils
emerge -D1n sys-devel/gcc-config  # sys-devel/gcc
emerge -D1n net-misc/rsync  # sys-kernel/linux-headers
emerge -D1n sys-apps/gawk
emerge -D1n sys-devel/crossdev
USE='ssl' emerge -D1n net-misc/curl
emerge -D1n app-crypt/libb2
emerge -D1n app-eselect/eselect-repository

# setup and compile cross toolchain
# make the crossdev repository
eselect repository create crossdev
echo "priority = 10" >> /etc/portage/repos.conf/eselect-repo.conf
echo "masters = gentoo" >> /etc/portage/repos.conf/eselect-repo.conf
echo "auto-sync = no" >> /etc/portage/repos.conf/eselect-repo.conf

#spin up the cross toolchain

crossdev -S -s4 --ex-gcc --ex-gdb --target x86_64-unknown-linux-gnu
PORTAGE_CONFIGROOT=/usr/x86_64-unknown-linux-gnu eselect profile set default/linux/amd64/23.0
x86_64-unknown-linux-gnu-emerge app-portage/cpuid2cpuflags
mkdir /usr/x86_64-unknown-linux-gnu/etc/portage/package.use
echo "*/* $(/usr/x86_64-unknown-linux-gnu/usr/bin/cpuid2cpuflags)" > /usr/x86_64-unknown-linux-gnu/etc/portage/package.use/00cpu-flags

# set up a customized make.conf
rm -Rf /usr/x86_64-unknown-linux-gnu/etc/portage/make.conf
cat > /usr/x86_64-unknown-linux-gnu/etc/portage/make.conf << 'EOF'
FEATURES="-news -usersandbox -pid-sandbox -parallel-fetch -collision-protect -sandbox noman noinfo nodoc"

CHOST=x86_64-unknown-linux-gnu
CBUILD=amd64-lfs-linux-gnu

ROOT=/usr/${CHOST}/

ACCEPT_KEYWORDS="${ARCH} ~${ARCH}"

USE="${ARCH}"

CFLAGS="-march=native -O2 -pipe -fomit-frame-pointer"
CXXFLAGS="${CFLAGS}"

# Be sure we dont overwrite pkgs from another repo..
PKGDIR=${ROOT}var/cache/binpkgs/
PORTAGE_TMPDIR=${ROOT}tmp/

LIBDIR_x86="lib"
LIBDIR_amd64="lib64"
DEFAULT_ABI="amd64"
MULTILIB_ABIS="amd64 x86"
EOF


#USE=build x86_64-unknown-linux-gnu-emerge -v1 baselayout
#USE=-pam x86_64-unknown-linux-gnu-emerge -v1 sys-libs/pam
#x86_64-unknown-linux-gnu-emerge -v1 @system

#USE=-nls x86_64-unknown-linux-gnu-emerge -v1 sys-libs/glibc

#build the inital world on /gentoo
#USE=build ROOT=/gentoo x86_64-unknown-linux-gnu-emerge -v1 baselayout
#USE=-nls ROOT=/gentoo x86_64-unknown-linux-gnu-emerge -v1 sys-libs/glibc

#backup
#ROOT=/gentoo SYSROOT=/gentoo x86_64-unknown-linux-gnu-emerge -O1n sys-apps/baselayout 
#