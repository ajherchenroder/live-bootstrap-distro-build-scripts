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
IUSE_IMPLICIT="kernel_linux elibc_glibc elibc_musl prefix prefix-guest"
IUSE_IMPLICIT="$IUSE_IMPLICIT x86 amd64"  # dev-libs/gmp
IUSE_IMPLICIT="$IUSE_IMPLICIT sparc"  # sys-libs/zlib
USE_EXPAND="PYTHON_TARGETS PYTHON_SINGLE_TARGET"
USE="kernel_linux build"
SKIP_KERNEL_CHECK=y  # linux-info.eclass
EOF
cat > /etc/portage/package.use << 'EOF'
dev-lang/python -ensurepip -ncurses -readline -sqlite -ssl
EOF
grep '^PYTHON_TARGETS=\|^PYTHON_SINGLE_TARGET=' \
    /var/db/repos/gentoo/profiles/base/make.defaults \
    >> /etc/portage/make.profile/make.defaults

# Specify what packages may or may not be installed in the live-bootstrap system
mkdir -p /etc/portage/profile
echo '*/*' > /etc/portage/package.mask
cat > /etc/portage/package.unmask << 'EOF'
app-alternatives/bzip2
app-alternatives/ninja
app-alternatives/lzip
app-alternatives/awk
app-arch/bzip2  # replaces files, live-bootstrap doesn't build libbz2 app-arch/bzip2
app-arch/lzip
app-arch/unzip
app-misc/pax-utils
app-portage/elt-patches
dev-build/autoconf-archive #
dev-build/libtool #
dev-build/autoconf
dev-build/autoconf-wrapper  # replaces files
dev-build/automake  # replaces files
dev-build/automake-wrapper  # replaces files
dev-build/make  # replaces files
dev-build/meson
dev-build/meson-format-array
dev-build/ninja
dev-lang/python
dev-lang/python-exec  # replaces files
dev-lang/python-exec-conf
dev-libs/expat
dev-libs/mpdecimal
dev-libs/popt
dev-libs/gmp
app-misc/mime-types
dev-python/flit-core
dev-python/gentoo-common
dev-python/gpep517
dev-python/installer
dev-python/jaraco-collections
dev-python/jaraco-context
dev-python/jaraco-functools
dev-python/jaraco-text
dev-python/more-itertools
dev-python/packaging
dev-python/setuptools
dev-python/wheel
dev-util/pkgconf  # replaces files, dev-lang/python ebuild requires "--keep-system-libs" option when cross-compiling
net-misc/rsync
sys-apps/findutils  # replaces files, portage requires 4.9, live-bootstrap provides 4.2.33
sys-apps/gentoo-functions
sys-apps/portage
sys-apps/gawk
sys-devel/binutils-config
sys-devel/gcc-config
sys-devel/gnuconfig
virtual/pkgconfig
EOF
cat > /etc/portage/profile/package.provided << 'EOF'
acct-user/portage-0
#app-alternatives/awk-0
app-alternatives/gzip-0
app-alternatives/lex-0
app-alternatives/yacc-0
app-arch/tar-1.27
app-arch/xz-utils-5.4.0
app-arch/zstd-0
app-crypt/libb2-0
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

# For some reason, make hangs when used in parallel, rebuild it first.
MAKEOPTS=-j1 ./portage/bin/emerge -D1n app-arch/lzip dev-build/make

# Upgrade python and install portage
./portage/bin/emerge -D1n sys-apps/portage

# Install BDEPENDs for cross-toolchain
emerge -D1n sys-devel/binutils-config  # sys-devel/binutils
emerge -D1n sys-devel/gcc-config  # sys-devel/gcc
emerge -D1n net-misc/rsync  # sys-kernel/linux-headers
emerge -D1n sys-kernel/linux-headers

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
ACCEPT_KEYWORDS="amd64"
EOF
cat > /cross/etc/portage/package.use << 'EOF'
sys-devel/gcc -sanitize -fortran
EOF
mkdir -p /cross/etc/portage/env/sys-devel
cat > /cross/etc/portage/env/sys-devel/gcc << 'EOF'
EXTRA_ECONF='--with-sysroot=$EPREFIX/usr/$CTARGET --enable-threads'
EOF
cat > /cross/etc/portage/package.mask << 'EOF'
>=sys-devel/gcc-14
EOF
# TODO: Build using gcc 14

PORTAGE_CONFIGROOT=/cross EPREFIX=/cross USE='headers-only' emerge -O1 sys-kernel/linux-headers
PORTAGE_CONFIGROOT=/cross EPREFIX=/cross USE='headers-only -multilib' emerge -O1 sys-libs/glibc 
PORTAGE_CONFIGROOT=/cross EPREFIX=/cross emerge -O1 sys-devel/binutils
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
exec /cross/usr/x86_64-unknown-linux-gnu/x86_64-bootstrap-linux-gnu/gcc-bin/*/x86_64-bootstrap-linux-gnu-$tool --sysroot=/gentoo "\$@"
EOF
chmod +x /cross/usr/bin/x86_64-bootstrap-linux-gnu-$tool
done
cat > /cross/usr/bin/x86_64-bootstrap-linux-gnu-pkg-config << 'EOF'
#!/bin/sh
export PKG_CONFIG_SYSROOT_DIR=/gentoo
export PKG_CONFIG_LIBDIR=/gentoo/usr/lib64/pkgconfig:/gentoo/usr/share/pkgconfig
export PKG_CONFIG_SYSTEM_INCLUDE_PATH=/gentoo/usr/include
export PKG_CONFIG_SYSTEM_LIBRARY_PATH=/gentoo/lib64:/gentoo/usr/lib64
exec pkg-config "$@"
EOF
chmod +x /cross/usr/bin/x86_64-bootstrap-linux-gnu-pkg-config

# Configure cross-compilation for final system
mkdir -p /gentoo.cfg/etc/portage
ln -sf ../../../var/db/repos/gentoo/profiles/default/linux/amd64/23.0 /gentoo.cfg/etc/portage/make.profile
cat > /gentoo.cfg/etc/portage/make.conf << 'EOF'
FETCHCOMMAND="curl -k --retry 3 -m 60 --ftp-pasv -o \"\${DISTDIR}/\${FILE}\" -L \"\${URI}\""
RESUMECOMMAND="curl -C - -k --retry 3 -m 60 --ftp-pasv -o \"\${DISTDIR}/\${FILE}\" -L \"\${URI}\""
FEATURES="-news -sandbox -usersandbox -pid-sandbox -parallel-fetch"
BINPKG_COMPRESS="bzip2"
CBUILD="x86_64-unknown-linux-gnu"
CHOST="x86_64-bootstrap-linux-gnu"
CFLAGS_x86="$CFLAGS_x86 -msse"  # https://bugs.gentoo.org/937637
CONFIG_SITE="$PORTAGE_CONFIGROOT/etc/portage/config.site"
USE="-* build $BOOTSTRAP_USE -zstd"
SKIP_KERNEL_CHECK=y  # linux-info.eclass
EOF
cat > /gentoo.cfg/etc/portage/package.use << 'EOF'
# https://gitweb.gentoo.org/proj/releng.git/tree/releases/portage/stages/profile/package.use.force/releng/alternatives
app-alternatives/lex flex
app-alternatives/yacc bison
app-alternatives/tar gnu
app-alternatives/gzip reference
app-alternatives/bzip2 reference
EOF
cat > /gentoo.cfg/etc/portage/config.site << 'EOF'
if [ "${CBUILD:-${CHOST}}" != "${CHOST}" ]; then
# https://gitweb.gentoo.org/proj/crossdev.git/tree/wrappers/site/linux
ac_cv_file__dev_ptmx=yes
ac_cv_file__dev_ptc=no
fi
EOF
cat > /gentoo.cfg/etc/portage/package.mask << 'EOF'
>=sys-devel/gcc-14
EOF
# TODO: Build using gcc 14
# TODO: USE=zstd causes binutils to try to link with target zstd instead of
#       host. zstd cannot be built for host due to lack of libatomic in gcc.

# Cross-compile a basic system
pkgs_build="$(PORTAGE_CONFIGROOT=/gentoo.cfg python3 -c 'import portage
print(*portage.util.stack_lists([portage.util.grabfile_package("%s/packages.build"%x)for x in portage.settings.profiles],incremental=1))')"
PORTAGE_CONFIGROOT=/gentoo.cfg ROOT=/gentoo SYSROOT=/gentoo emerge -O1n \
    sys-apps/baselayout \
    sys-kernel/linux-headers \
    sys-libs/glibc 
PORTAGE_CONFIGROOT=/gentoo.cfg ROOT=/gentoo SYSROOT=/gentoo emerge -D1n $pkgs_build









# Set up final system
mkdir -p /gentoo/etc/portage
ln -sf ../../var/db/repos/gentoo/profiles/default/linux/amd64/23.0 /gentoo/etc/portage/make.profile
echo 'nameserver 1.1.1.1' > /gentoo/etc/resolv.conf
echo 'C.UTF8 UTF-8' > /gentoo/etc/locale.gen

# Copy ::gentoo repo and distfiles
rsync -aP /var/db/repos/ /gentoo/var/db/repos
rsync -aP /var/cache/distfiles/ /gentoo/var/cache/distfiles




