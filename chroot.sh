#! /bin/bash
# things we can do inside a chroot

pacman -Syy
pacman -S nbd parted btrfs-progs --noconfirm

cd /etc/ssh
ssh-keygen -A

mv /usr/bin/init /usr/bin/init.orig
ln -s /install.sh /usr/bin/init
