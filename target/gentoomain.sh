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
/usr/sbin/fdisk -l | grep /dev
read -p "Enter the partion to build Gentoo on (sdxx) -> " USEPART
if ! test -d /gentoo 
then 
    mkdir /gentoo
fi
mount -v -t ext4 /dev/$USEPART /gentoo

mkdir /gentoo
cp gentoomk.sh /gentoo
cp gentoomk2.sh /gentoo
./gentoomk.sh
chroot /gentoo /bin/bash --login gentoomk2.sh


