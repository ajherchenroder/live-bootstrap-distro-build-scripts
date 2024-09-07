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

mkdir -p /var/cache/distfiles; cd /var/cache/distfiles
curl -LO http://gitweb.gentoo.org/proj/portage.git/snapshot/portage-3.0.65.tar.bz2
curl -LO http://distfiles.gentoo.org/snapshots/squashfs/gentoo-20240801.xz.sqfs
curl -LO https://github.com/plougher/squashfs-tools/archive/refs/tags/4.6.1/squashfs-tools-4.6.1.tar.gz
cd /tmp

# This patch avoids using the _ctypes module in portage
cat > portage.patch << 'EOF'
+++ b/lib/portage/util/compression_probe.py
@@ -1,13 +1,13 @@
 # Copyright 2015-2020 Gentoo Authors
 # Distributed under the terms of the GNU General Public License v2

-import ctypes
 import errno
 import re


 from portage import _encodings, _unicode_encode
 from portage.exception import FileNotFound, PermissionDenied
+from portage.util._ctypes import ctypes

 _compressors = {
     "bzip2": {
@@ -49,7 +49,7 @@ _compressors = {
         # if the current architecture can support it, which is true when
         # sizeof(long) is at least 8 bytes.
         "decompress": "zstd -d"
-        + (" --long=31" if ctypes.sizeof(ctypes.c_long) >= 8 else ""),
+        + (" --long=31" if ctypes and ctypes.sizeof(ctypes.c_long) >= 8 else ""),
         "package": "app-arch/zstd",
     },
 }
EOF

# Build squashfs-tools to extract the ::gentoo tree
tar xf /var/cache/distfiles/squashfs-tools-4.6.1.tar.gz
cd squashfs-tools-4.6.1
make -C squashfs-tools install \
    INSTALL_PREFIX=/usr \
    XZ_SUPPORT=1
cd ..
rm -rf squashfs-tools-4.6.1

# Unpack the ::gentoo tree
unsquashfs /var/cache/distfiles/gentoo-20240801.xz.sqfs
mkdir -p /var/db/repos
rm -rf /var/db/repos/gentoo
mv squashfs-root /var/db/repos/gentoo

# Install temporary copy of portage
tar xf /var/cache/distfiles/portage-3.0.65.tar.bz2
cd portage-3.0.65
patch -p1 -i ../portage.patch
cd ..
ln -sf portage-3.0.65 portage

# Add portage user/group
echo 'portage:x:250:250:portage:/var/tmp/portage:/bin/false' >> /etc/passwd
echo 'portage::250:portage' >> /etc/group

# Configure portage
mkdir -p /etc/portage/make.profile
cat > /etc/portage/make.profile/make.defaults << 'EOF'
FEATURES="-news -sandbox -usersandbox -pid-sandbox -parallel-fetch"
BINPKG_COMPRESS="bzip2"
ARCH="x86"
ABI="$ARCH"
DEFAULT_ABI="$ARCH"
ACCEPT_KEYWORDS="$ARCH"
CHOST="i386-unknown-linux-musl"
LIBDIR_x86="lib/i386-unknown-linux-musl"
PKG_CONFIG_PATH="/usr/lib/i386-unknown-linux-musl/pkgconfig"
IUSE_IMPLICIT="kernel_linux elibc_glibc elibc_musl prefix prefix-guest"
USE="kernel_linux elibc_musl python_targets_python3_12"
EOF
cat > /etc/portage/package.use << 'EOF'
dev-lang/python -readline -ncurses
EOF

# Install dependencies to make emerge work nicely
FETCHCOMMAND='curl -o "${DISTDIR}/${FILE}" -L "${URI}"'
FETCHCOMMAND="$FETCHCOMMAND" MAKEOPTS=-j1 ./portage/bin/emerge -O1 app-arch/lzip
FETCHCOMMAND="$FETCHCOMMAND" MAKEOPTS=-j1 ./portage/bin/emerge -O1 dev-build/make
FETCHCOMMAND="$FETCHCOMMAND" ./portage/bin/emerge -O1 net-misc/wget

# Upgrade python so we can use it to cross-compile later on
./portage/bin/emerge -O1 dev-build/autoconf-wrapper
./portage/bin/emerge -O1 dev-build/autoconf
./portage/bin/emerge -O1 dev-build/automake-wrapper
./portage/bin/emerge -O1 dev-build/automake
./portage/bin/emerge -O1 sys-apps/gentoo-functions
./portage/bin/emerge -O1 app-portage/elt-patches
./portage/bin/emerge -O1 dev-libs/mpdecimal
./portage/bin/emerge -O1 dev-libs/expat
mv /bin/bzip2 /bin/bzip2-reference
ln -s bzip2-reference /bin/bzip2
./portage/bin/emerge -O1 app-arch/bzip2
./portage/bin/emerge -O1 dev-lang/python
./portage/bin/emerge -O1 dev-lang/python-exec

# Install the rest of the dependencies for meson
./portage/bin/emerge -O1 dev-python/gpep517
./portage/bin/emerge -O1 app-arch/unzip
./portage/bin/emerge -O1 dev-python/installer
./portage/bin/emerge -O1 dev-python/flit-core
./portage/bin/emerge -O1 dev-python/packaging
./portage/bin/emerge -O1 dev-python/more-itertools
./portage/bin/emerge -O1 dev-python/ordered-set
./portage/bin/emerge -O1 dev-python/jaraco-text
./portage/bin/emerge -O1 dev-python/jaraco-functools
./portage/bin/emerge -O1 dev-python/jaraco-context
./portage/bin/emerge -O1 dev-python/wheel
./portage/bin/emerge -O1 dev-python/setuptools
./portage/bin/emerge -O1 dev-build/meson
./portage/bin/emerge -O1 dev-build/meson-format-array
./portage/bin/emerge -O1 dev-build/ninja

# Finally install portage itself
./portage/bin/emerge -O1 sys-apps/portage

# Install pax-utils to allow stripping binaries (requires meson...)
emerge -O1 app-misc/pax-utils

# Fix "find" warnings in emerge
emerge -O1 sys-apps/findutils

# Install additional BDEPENDs
emerge -O1 sys-devel/binutils-config  # sys-devel/binutils
emerge -O1 sys-devel/gcc-config  # sys-devel/gcc
emerge -O1 net-misc/rsync  # sys-kernel/linux-headers
emerge -O1 dev-util/pkgconf  # dev-lang/python requires --keep-system-libs option when cross compiling

# Add cross compiler to PATH
cat > /etc/env.d/50baselayout << 'EOF'
PATH=/cross/usr/bin:/usr/bin
EOF
env-update

# Set up cross compiler
mkdir -p /cross/etc/portage
ln -sf /etc/portage/make.profile /cross/etc/portage/make.profile
cat > /cross/etc/portage/make.conf << 'EOF'
USE="prefix multilib"
CTARGET="x86_64-bootstrap-linux-gnu"
LIBDIR_x86="lib"
LIBDIR_amd64="lib64"
DEFAULT_ABI="amd64"
MULTILIB_ABIS="amd64 x86"
EOF
cat > /cross/etc/portage/package.use << 'EOF'
sys-devel/gcc -sanitize -fortran
EOF
mkdir -p /cross/etc/portage/env/sys-devel
cat > /cross/etc/portage/env/sys-devel/gcc << 'EOF'
EXTRA_ECONF='--with-sysroot=$EPREFIX/usr/$CTARGET --enable-threads'
EOF

# TODO: Build sys-libs/glibc in /gentoo instead, to avoid extra rebuilding later
PORTAGE_CONFIGROOT=/cross EPREFIX=/cross emerge -O1 sys-devel/binutils
PORTAGE_CONFIGROOT=/cross EPREFIX=/cross USE='headers-only' emerge -O1 sys-kernel/linux-headers
PORTAGE_CONFIGROOT=/cross EPREFIX=/cross USE='headers-only -multilib' emerge -O1 sys-libs/glibc 
PORTAGE_CONFIGROOT=/cross EPREFIX=/cross USE='-cxx' emerge -O1 sys-devel/gcc
PORTAGE_CONFIGROOT=/cross EPREFIX=/cross emerge -O1 sys-kernel/linux-headers
PORTAGE_CONFIGROOT=/cross EPREFIX=/cross emerge -O1 sys-libs/glibc
PORTAGE_CONFIGROOT=/cross EPREFIX=/cross emerge -O1 sys-devel/gcc

# Reconfigure cross toolchain for final system
cat > /cross/usr/lib/gcc/x86_64-bootstrap-linux-gnu/specs << 'EOF'
*link:
+ %{!shared:%{!static:%{!static-pie:-dynamic-linker %{m32:/lib/ld-linux.so.2;:/lib64/ld-linux-x86-64.so.2}}}}
EOF
for tool in gcc g++; do
rm -f /cross/usr/bin/x86_64-bootstrap-linux-gnu-$tool
cat > /cross/usr/bin/x86_64-bootstrap-linux-gnu-$tool << EOF
#!/bin/sh
exec /cross/usr/i386-unknown-linux-musl/x86_64-bootstrap-linux-gnu/gcc-bin/*/x86_64-bootstrap-linux-gnu-$tool --sysroot=/gentoo "\$@"
EOF
chmod +x /cross/usr/bin/x86_64-bootstrap-linux-gnu-$tool
done
cat > /cross/usr/bin/x86_64-bootstrap-linux-gnu-pkg-config << 'EOF'
#!/bin/sh
export PKG_CONFIG_SYSROOT_DIR=/gentoo
export PKG_CONFIG_LIBDIR=/gentoo/usr/lib64/pkgconfig
export PKG_CONFIG_PATH=/gentoo/usr/share/pkgconfig
export PKG_CONFIG_SYSTEM_INCLUDE_PATH=/gentoo/usr/include
export PKG_CONFIG_SYSTEM_LIBRARY_PATH=/gentoo/lib64:/gentoo/usr/lib64
exec pkg-config "$@"
EOF
chmod +x /cross/usr/bin/x86_64-bootstrap-linux-gnu-pkg-config

# Configure cross-compilation for final system
mkdir -p /gentoo.cfg/etc/portage
ln -sf ../../../var/db/repos/gentoo/profiles/default/linux/amd64/23.0 /gentoo.cfg/etc/portage/make.profile
cat > /gentoo.cfg/etc/portage/make.conf << 'EOF'
FEATURES="-news -sandbox -usersandbox -pid-sandbox -parallel-fetch"
BINPKG_COMPRESS="bzip2"
CBUILD="i386-unknown-linux-musl"
CHOST="x86_64-bootstrap-linux-gnu"
CFLAGS_x86="$CFLAGS_x86 -msse"  # https://bugs.gentoo.org/937637
CONFIG_SITE="$PORTAGE_CONFIGROOT/etc/portage/config.site"
USE="-* build $BOOTSTRAP_USE -zstd"
EOF
cat > /gentoo.cfg/etc/portage/config.site << 'EOF'
if [ "${CBUILD:-${CHOST}}" != "${CHOST}" ]; then
# Settings grabbed from crossdev
ac_cv_file__dev_ptmx=yes
ac_cv_file__dev_ptc=no
fi
EOF

# Cross-compile just enough to build everything
py=$(PORTAGE_CONFIGROOT=/gentoo.cfg portageq envvar PYTHON_SINGLE_TARGET | sed 's/^python//;s/_/./g')
PORTAGE_CONFIGROOT=/gentoo.cfg ROOT=/gentoo SYSROOT=/gentoo emerge -O1n \
    sys-apps/baselayout \
    sys-kernel/linux-headers \
    sys-libs/glibc \
    sys-libs/zlib \
    sys-devel/binutils \
    dev-libs/gmp \
    dev-libs/mpfr \
    dev-libs/mpc \
    sys-devel/gcc \
    \
    app-arch/bzip2 \
    app-arch/xz-utils \
    dev-libs/expat \
    dev-libs/libffi \
    dev-libs/mpdecimal \
    sys-apps/util-linux \
    sys-libs/libxcrypt \
    dev-lang/python:$py \
    \
    dev-lang/python-exec \
    sys-apps/portage \
    \
    sys-libs/ncurses \
    sys-libs/readline \
    app-shells/bash \
    \
    sys-apps/coreutils \
    sys-apps/findutils \
    sys-apps/sed \
    sys-apps/grep \
    sys-apps/gawk \
    sys-devel/patch \
    app-arch/tar \
    app-arch/gzip \
    dev-build/make \
    \
    dev-libs/openssl \
    net-misc/wget \
    app-misc/ca-certificates \
    \
    app-crypt/libmd \
    dev-libs/libbsd \
    sys-apps/shadow

# Set up final system
mkdir -p /gentoo/etc/portage
ln -sf ../../var/db/repos/gentoo/profiles/default/linux/amd64/23.0 /gentoo/etc/portage/make.profile
echo 'nameserver 1.1.1.1' > /gentoo/etc/resolv.conf
echo 'C.UTF8 UTF-8' > /gentoo/etc/locale.gen

# Optional: Back up the system
tar --sort=name -cf /gentoo.tar -C /gentoo .
bzip2 -9v /gentoo.tar

# Copy ::gentoo repo and distfiles
rsync -aP /var/db/repos/ /gentoo/var/db/repos
rsync -aP /var/cache/distfiles/ /gentoo/var/cache/distfiles
cd /gentoo
emerge -O1n \
    app-alternatives/awk \
    app-alternatives/bzip2 \
    app-alternatives/gzip \
    app-alternatives/lex \
    app-alternatives/ninja \
    app-alternatives/tar \
    app-alternatives/yacc

# Finish installing stage1 dependencies
pkgs_build="$(python3 -c 'import portage
print(*portage.util.stack_lists([portage.util.grabfile_package("%s/packages.build" % x) for x in portage.settings.profiles], incremental=1))')"
USE="-* build $(portageq envvar BOOTSTRAP_USE)" CHOST="$(gcc -dumpmachine)" \
    emerge -1Dn $pkgs_build
emerge -c  # Make sure the dependency tree is consistent

# Change CHOST and build OpenMP support (stage2-ish)
emerge -1 sys-devel/binutils
emerge -o sys-devel/gcc
EXTRA_ECONF=--disable-bootstrap emerge -O1 sys-devel/gcc
emerge -1 $(portageq expand_virtual / virtual/libc)
emerge -1 dev-lang/perl  # https://bugs.gentoo.org/937918

# Rebuild everything (stage3)
USE='-filecaps -http2' emerge -e @system
emerge -DN @system
emerge -c



