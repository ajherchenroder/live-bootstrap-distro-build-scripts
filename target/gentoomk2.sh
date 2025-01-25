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

emerge -O1n \
    app-alternatives/awk \
    app-alternatives/bzip2 \
    app-alternatives/gzip \
    app-alternatives/lex \
    app-alternatives/ninja \
    app-alternatives/tar \
    app-alternatives/yacc

# Sandbox fails to rebuild itself at first until it's built without sandbox...
# TODO: Why, though?
FEATURES='-sandbox -usersandbox' emerge -1 sys-apps/sandbox

# Change CHOST and build OpenMP support (stage2-ish)
#go back to default CHOST
sed '/CHOST="x86_64-bootstrap-linux-gnu"/d' /gentoo.cfg/etc/portage/make.conf

emerge -1 sys-devel/binutils
emerge -o sys-devel/gcc
EXTRA_ECONF=--disable-bootstrap emerge -1 sys-devel/gcc
emerge -1 dev-lang/perl  # https://bugs.gentoo.org/937918

# USE flag rationale:
# https://gitweb.gentoo.org/proj/releng.git/tree/releases/portage/stages/package.use/releng/no-filecaps
# https://gitweb.gentoo.org/proj/releng.git/tree/releases/portage/stages/package.use/releng/circular



# Rebuild everything (stage3)
USE='-filecaps -http2 -http3 -quic -curl_quic_openssl' emerge -e @system
emerge -c

while getopts L flag; 
do
     case "${flag}" in
        L) REMOTE="-L";; #download from the local repositories
     esac
done

./gentoomk3.sh "$REMOTE"


