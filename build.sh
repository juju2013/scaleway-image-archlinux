# !/usr/bin/env bash
# Build a custom archlinux arm image
# This image is supposed to run on a [C1](http://scaleway.com/) server

TAR=/usr/bin/tar
DST=`pwd`
IMG=`dd if=/dev/urandom bs=4K count=1 status=none | sha1sum | cut -d ' ' -f 1`.tar
LOG=build.log
ROOTFS=$(mktemp -d $DST/.rootfs-archlinux-XXXXXXXXXX)
chmod 755 $ROOTFS

echo "Getting latest archlinuxarm image..."
echo > $LOG
#wget http://archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz >> $LOG

echo "Extracting ..."
sudo $TAR -xzpf ArchLinuxARM-armv7-latest.tar.gz -C $ROOTFS --warning=none 2>&1 >> $LOG

echo "Building ..."
sudo rm $ROOTFS/etc/resolv.conf 2>&1 >> /dev/null
sudo mkdir -p $ROOTFS/root/.ssh/
sudo touch $ROOTFS/root/.ssh/authorized_keys
sudo cp -vr patches/etc/* $ROOTFS/etc/ >> $LOG
sudo cp -vr patches/usr/* $ROOTFS/usr/ >> $LOG
sudo cp install.sh $ROOTFS/
sudo chown root:root $ROOTFS/install.sh
sudo chmod 0755 $ROOTFS/install.sh
sudo cp chroot.sh $ROOTFS/root/
sudo chmod 0755 $ROOTFS/root/chroot.sh

echo "Chrooting ..."
sudo mount --bind /dev ${ROOTFS}/dev
sudo mount --bind /dev/pts ${ROOTFS}/dev/pts
sudo mount -t proc proc ${ROOTFS}/proc
sudo mount -t sysfs sys ${ROOTFS}/sys
sudo arch-chroot ${ROOTFS} /bin/bash /root/chroot.sh
sudo umount ${ROOTFS}/dev/pts
sudo umount ${ROOTFS}/dev
sudo umount ${ROOTFS}/proc
sudo umount ${ROOTFS}/sys


echo "Creating ssh keys"
sudo sh -c "cat .keys/*.pub >> $ROOTFS/root/.ssh/authorized_keys"
sudo chmod 0444 $ROOTFS/root/.ssh/authorized_keys
sudo chown -R root:root $ROOTFS/root


echo "************* Here's your new host keys fingerprint *********************"
ssh-keygen -E md5 -lf $ROOTFS/etc/ssh/ssh_host_rsa_key.pub
ssh-keygen -E sha256 -lf $ROOTFS/etc/ssh/ssh_host_rsa_key.pub
ssh-keygen -E md5 -lf $ROOTFS/etc/ssh/ssh_host_dsa_key.pub
ssh-keygen -E sha256 -lf $ROOTFS/etc/ssh/ssh_host_dsa_key.pub
ssh-keygen -E md5 -lf $ROOTFS/etc/ssh/ssh_host_ecdsa_key.pub
ssh-keygen -E sha256 -lf $ROOTFS/etc/ssh/ssh_host_ecdsa_key.pub
ssh-keygen -E md5 -lf $ROOTFS/etc/ssh/ssh_host_ed25519_key.pub
ssh-keygen -E sha256 -lf $ROOTFS/etc/ssh/ssh_host_ed25519_key.pub


cd $ROOTFS
sudo $TAR -cpf $DST/$IMG . >> $LOG
echo "Target filesyste is named $IMG, dont forget to push it to your repo"
cd
sudo rm -rf $ROOTFS

echo Finished!

