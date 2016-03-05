# !/usr/bin/env bash
# Build a custom alpine arm image
# This image is supposed to run on a [C1](http://scaleway.com/) server
# Copyright (c) 2015 juju2013@github

if [ -z "$DESTINATION_URL" ]; then
	echo Please define DESTINATION_URL first
	exit 1
fi

export DST=`pwd`/out
echo "Cleaning ..."
sudo rm -rf $DST/.initfs*
sudo rm -rf $DST/.rootfs*

TAR=/usr/bin/tar
export MIRROR=http://nl.alpinelinux.org/alpine/
export APKTOOL=apk-tools-static-2.6.5-r1.apk
export IMG=`dd if=/dev/urandom bs=4K count=1 status=none | sha1sum | cut -d ' ' -f 1`.tar
export iIMG=`dd if=/dev/urandom bs=4K count=1 status=none | sha1sum | cut -d ' ' -f 1`.tar
#export IMG=al.tar
#export iIMG=ai.tar
export ROOTFS=$(mktemp -d $DST/.rootfs-alpinelinux-XXXXXXXXXX)
export INITFS=$(mktemp -d $DST/.initfs-alpinelinux-XXXXXXXXXX)
chmod 755 $ROOTFS
mkdir $ROOTFS/tmp

echo "Building base image from $MIRROR..."
pushd $ROOTFS/tmp
wget -O $APKTOOL $MIRROR/latest-stable/main/armhf/$APKTOOL
tar -xzf $APKTOOL
popd
sudo bash <<_EOF_
$ROOTFS/tmp/sbin/apk.static -v -X $MIRROR/latest-stable/main -U --allow-untrusted --root $ROOTFS --initdb add alpine-base iproute2
mknod -m 666 $ROOTFS/dev/full c 1 7 
mknod -m 666 $ROOTFS/dev/ptmx c 5 2 
mknod -m 644 $ROOTFS/dev/random c 1 8 
mknod -m 644 $ROOTFS/dev/urandom c 1 9 
mknod -m 666 $ROOTFS/dev/zero c 1 5 
mknod -m 666 $ROOTFS/dev/tty c 5 0
cp /etc/resolv.conf $ROOTFS/etc/
mkdir -p $ROOTFS/root/
chmod 0700 $ROOTFS/root/
mkdir -p $ROOTFS/root/.ssh/
touch $ROOTFS/root/.ssh/authorized_keys
cp -r patches/etc/* $ROOTFS/etc/
cp -r patches/usr/* $ROOTFS/usr/
cp chroot.sh $ROOTFS/root/
chmod 0755 $ROOTFS/root/chroot.sh
cp oc-sync-kernel-modules $INITFS/
cp oc-sync-kernel-modules $ROOTFS/usr/local/bin/
sed -i 's/#ttyS0::.*/ttyS0::respawn:\/sbin\/getty -L ttyS0 9600 vt102/' $ROOTFS/etc/inittab
echo "$MIRROR/latest-stable/main" > $ROOTFS/etc/apk/repositories
_EOF_

echo "Chrooting ..."
sudo mount --bind /dev ${ROOTFS}/dev
sudo mount --bind /dev/pts ${ROOTFS}/dev/pts
sudo mount -t proc proc ${ROOTFS}/proc
sudo mount -t sysfs sys ${ROOTFS}/sys
sudo mount --bind ${INITFS} ${ROOTFS}/mnt
sudo chroot ${ROOTFS} /bin/sh -l /root/chroot.sh
sudo umount ${ROOTFS}/dev/pts
sudo umount ${ROOTFS}/dev
sudo umount ${ROOTFS}/proc
sudo umount ${ROOTFS}/sys
sudo umount ${ROOTFS}/mnt


echo "Creating ssh keys"
sudo sh -c "cat keys/*.pub >> $ROOTFS/root/.ssh/authorized_keys"
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


pushd $ROOTFS
sudo $TAR -cpf $DST/$IMG . 
popd
#pushd $INITFS
#sudo $TAR -cpf $DST/$iIMG . >> $LOG
#popd

#envsubst < $FILE_RUN > $DST/$FILE_RUN
#chmod +x $DST/$FILE_RUN
#envsubst < $FILE_INST > $DST/$FILE_INST
#chmod +x $DST/$FILE_INST

sudo rm -rf $ROOTFS
sudo rm -rf $INITFS
echo Finished!

cat << __EOF__
To buil the target server:
  * upload $iIMG and $IMG, to $DESTINATION_URL
  * create a new C1 instance and add 'INIRD_POST_SHELL=1' tag to it
  * boot, connect to the console, then follow the README !
__EOF__


