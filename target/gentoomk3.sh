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
MEM=$(free -h | awk '/Mem/ { print $2 }') 
MEM="${MEM//G/}"
MEM="${MEM//i/}"
MAXCOREM=$(echo "scale=0; $MEM / 4" | bc)
if [ $(nproc) -ge $MAXCOREM ]; then
   MAXCORE=$MAXCOREM
else 
   MAXCORE=$(nproc)
fi

emerge --sync
emerge --oneshot sys-apps/portage
emerge --verbose --update --deep --changed-use @world
emerge --depclean

echo dev-util/catalyst >> /etc/portage/package.accept_keywords
echo ">=sys-apps/util-linux-2.39.4-r1 python" >>/etc/portage/package.use
echo ">=sys-boot/grub-2.12-r4 grub_platforms_efi-32" >>/etc/portage/package.use
emerge dev-util/catalyst
USE=lzma emerge sys-fs/squashfs-tools
ROOT="$PWD/stage" USE=build emerge -1 sys-apps/baselayout
ROOT="$PWD/stage" QUICKPKG_DEFAULT_OPTS=--include-config=y emerge --quickpkg-direct=y -K @system
#break circular dependencies in stage 1
ROOT="$PWD/stage" USE=-nls emerge sys-devel/m4
ROOT="$PWD/stage" USE=-nls emerge sys-apps/help2man
ROOT="$PWD/stage" MAKEOPTS=-j$MAXCORE emerge =llvm-core/llvm-19.1.4
ROOT="$PWD/stage" MAKEOPTS=-j$MAXCORE emerge =llvm-core/llvm-18.1.8-r6
mkdir stage/etc/portage  # catalyst breaks otherwise...
tar cf stage.tar -C stage .
rm -rf stage
xz -9v stage.tar
mkdir /var/tmp/catalyst/
mkdir /var/tmp/catalyst/builds/
mkdir -p /var/tmp/catalyst/builds/23.0-default
cp stage.tar.xz /var/tmp/catalyst/builds/23.0-default/stage3-amd64-openrc-latest.tar.xz
cp /var/tmp/catalyst/builds/23.0-default/stage3-amd64-openrc-latest.tar.xz /var/tmp/catalyst/builds/23.0-default/livecd-stage1-amd64-20250101
cp /var/tmp/catalyst/builds/23.0-default/stage3-amd64-openrc-latest.tar.xz /var/tmp/catalyst/builds/23.0-default/stage3-amd64-systemd-latest.tar.xz

# the Linux kernel in use doesn't support xz compressed squashfs. 
# using squashfs-tools to convert the snapshot to a standard squashfs.
cd /

while getopts L flag; 
do
     case "${flag}" in
        L) REMOTE="local";; #download from the local repositories
     esac
done
#if test "$REMOTE" = "local"; then 
#   echo "local"
#   wget http://192.168.2.102/gentoo/gentoo-20250101.xz.sqfs
#else
#   echo "remote"
#   wget http://distfiles.gentoo.org/snapshots/squashfs/gentoo-20250101.xz.sqfs
#fi
mkdir /var/tmp/catalyst/snapshots
catalyst --snapshot stable
cp /var/tmp/catalyst/snapshots/gentoo-*.sqfs /var/tmp/catalyst/snapshots/gentoo-20250101.sqfs
#mkdir -p /var/tmp/catalyst/snapshots
#unsquashfs /gentoo-20250101.xz.sqfs
#rm gentoo-20250101.xz.sqfs
#mksquashfs /squashfs-root /var/tmp/catalyst/snapshots/gentoo-20250101.sqfs
#rm -Rf /squashfs-root

#if test "$REMOTE" = "local"; then 
   echo "local"
   wget http://192.168.2.102/gentoo/releng.tar.gz
   tar -xvf releng.tar.gz
#else
#   echo "remote"
#   git clone https://anongit.gentoo.org/git/proj/releng.git
#   git -C releng checkout 'master@{2025-01-01}'
#fi

#git -C releng checkout 'master@{2025-01-01}'
#systemD is broken in this snapshot
sed -e 's|@TIMESTAMP@|20250101|g' \
    -e 's|@TREEISH@|20250101|g' \
    -e 's|@REPO_DIR@|'"$PWD/releng"'|g' \
    -i \
    releng/releases/specs/amd64/stage1-openrc-23.spec \
    releng/releases/specs/amd64/stage3-openrc-23.spec \
    releng/releases/specs/amd64/installcd-stage1.spec \
    releng/releases/specs/amd64/installcd-stage2-minimal.spec\
    releng/releases/specs/amd64/stage1-systemd-23.spec \
    releng/releases/specs/amd64/stage3-systemd-23.spec 
#raise the job count to equal the max core count for the size of the memory
sed -i 's/# jobs = 4/jobs = '$MAXCORE'/g' /etc/catalyst/catalyst.conf
# remove net-proxy/tsocks and dante from installcd specs do to GCC 14 compile issues
sed -i '/socks5/d' /releng/releases/specs/amd64/installcd-stage1.spec
sed -i '/tsocks/d' /releng/releases/specs/amd64/installcd-stage1.spec
sed -i '/dante/d' /releng/releases/specs/amd64/installcd-stage1.spec
# remove items from installcd specs do to python incompatibility.
sed -i '/xen-tools/d' /releng/releases/specs/amd64/installcd-stage1.spec
sed -i '/libsmbios/d' /releng/releases/specs/amd64/installcd-stage1.spec

catalyst -f /releng/releases/specs/amd64/stage1-openrc-23.spec
catalyst -f /releng/releases/specs/amd64/stage3-openrc-23.spec
catalyst -f /releng/releases/specs/amd64/stage1-systemd-23.spec
catalyst -f /releng/releases/specs/amd64/stage3-systemd-23.spec
catalyst -f /releng/releases/specs/amd64/installcd-stage1.spec
catalyst -f /releng/releases/specs/amd64/installcd-stage2-minimal.spec

mkdir /output
cp /var/tmp/catalyst/builds/23.0-default/stage3-amd64-openrc-20250101.tar.xz /output/stage3-amd64-openrc-latest.tar.xz 
#cp /var/tmp/catalyst/builds/23.0-default/stage3-amd64-openrc-latest.tar.xz /output
#cp /var/tmp/catalyst/builds/23.0-default/stage3-amd64-systemd-latest.tar.xz /output
cp /var/tmp/catalyst/builds/23.0-default/stage3-amd64-systemd-20250101.tar.xz /output/stage3-amd64-systemd-latest.tar.xz 
cp /var/tmp/catalyst/builds/23.0-default/install-amd64-minimal-20250101.iso /output
