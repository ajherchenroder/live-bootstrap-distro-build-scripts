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
echo dev-util/catalyst >> /etc/portage/package.accept_keywords
echo ">=sys-apps/util-linux-2.39.4-r1 python" >>/etc/portage/package.use
echo ">=sys-boot/grub-2.12-r4 grub_platforms_efi-32" >>/etc/portage/package.use
emerge dev-util/catalyst

ROOT="$PWD/stage" USE=build emerge -1 sys-apps/baselayout
ROOT="$PWD/stage" QUICKPKG_DEFAULT_OPTS=--include-config=y emerge --quickpkg-direct=y -K @system
mkdir stage/etc/portage  # catalyst breaks otherwise...
tar cf stage.tar -C stage .
rm -rf stage
xz -9v stage.tar
mkdir /var/tmp/catalyst/
mkdir /var/tmp/catalyst/builds/
mkdir -p /var/tmp/catalyst/builds/23.0-default
mv stage.tar.xz /var/tmp/catalyst/builds/23.0-default/stage3-amd64-openrc-latest.tar.xz
cp /var/tmp/catalyst/builds/23.0-default/stage3-amd64-openrc-latest.tar.xz /var/tmp/catalyst/builds/23.0-default/livecd-stage1-amd64-20240801
wget http://distfiles.gentoo.org/snapshots/squashfs/gentoo-20240801.xz.sqfs
mkdir -p /var/tmp/catalyst/snapshots
mv gentoo-20240801.xz.sqfs /var/tmp/catalyst/snapshots/gentoo-20240801.xz.sqfs

git clone https://anongit.gentoo.org/git/proj/releng.git
git -C releng checkout 'master@{2024-08-01}'

sed -e 's|@TIMESTAMP@|20240801|g' \
    -e 's|@TREEISH@|20240801|g' \
    -e 's|@REPO_DIR@|'"$PWD/releng"'|g' \
    -i \
    releng/releases/specs/amd64/stage1-openrc-23.spec \
    releng/releases/specs/amd64/stage3-openrc-23.spec \
    releng/releases/specs/amd64/installcd-stage1.spec \
    releng/releases/specs/amd64/installcd-stage2-minimal.spec
catalyst -f releng/releases/specs/amd64/stage1-openrc-23.spec
catalyst -f releng/releases/specs/amd64/stage3-openrc-23.spec
catalyst -f releng/releases/specs/amd64/installcd-stage1.spec
catalyst -f releng/releases/specs/amd64/installcd-stage2-minimal.spec
