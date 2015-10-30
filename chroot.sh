#! /bin/bash
# things we can do inside a chroot

pacman -Syy
pacman -S btrfs-progs wget --noconfirm

cd /etc/ssh
ssh-keygen -A

#--- prepare 1st boot image
function cpAllBinaries {
  BIN=$1
	LIBS=$(ldd $BIN | sed -e 's/.* =>//' -e 's/\( \/.\)/\1/' -e 's/(.*)//')
	cp -Lv --parents $BIN $ROOTFS/
	cp -Lv --parents $LIBS $ROOTFS/
}

ROOTFS=/mnt
cpAllBinaries `which mkfs.btrfs`
cpAllBinaries `which cryptsetup`
cpAllBinaries `which btrfs`
cpAllBinaries `which blkid`
cpAllBinaries `which lsblk`
#cpAllBinaries `which parted`
cpAllBinaries `which wget`
cpAllBinaries `which bash`

#--- preserve busybox's wget
mv $ROOTFS/usr/bin/wget $ROOTFS/usr/bin/wget.new
