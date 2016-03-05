#! /bin/sh
# things we can do inside a chroot

apk update
apk add btrfs-progs wget iproute2 openssh cryptsetup util-linux wget

cd /etc/ssh
ssh-keygen -A

#--- prepare 1st boot image
cpAllBinaries () {
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
#cpAllBinaries `which bash`

#--- preserve busybox's wget
mv $ROOTFS/usr/bin/wget $ROOTFS/usr/bin/wget.new
