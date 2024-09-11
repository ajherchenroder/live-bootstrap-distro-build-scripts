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
USE='-filecaps -http2' emerge  @system
emerge -DN @system
emerge -c



