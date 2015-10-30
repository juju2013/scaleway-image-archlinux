# !/usr/bin/env bash
# Build a custom archlinux arm image
# This image is supposed to run on a [C1](http://scaleway.com/) server

if [ -z "$DESTINATION_URL" ]; then
	echo Please define DESTINATION_URL first
	exit 1
fi
TAR=/usr/bin/tar
export DST=`pwd`/out
export IMG=`dd if=/dev/urandom bs=4K count=1 status=none | sha1sum | cut -d ' ' -f 1`.tar
export iIMG=`dd if=/dev/urandom bs=4K count=1 status=none | sha1sum | cut -d ' ' -f 1`.tar
export iIMG=init.tar
export IMG=test.tar
FILE_INST=c1install
FILE_RUN=c1run
LOG=build.log
ROOTFS=$(mktemp -d $DST/.rootfs-archlinux-XXXXXXXXXX)
INITFS=$(mktemp -d $DST/.initfs-archlinux-XXXXXXXXXX)
chmod 755 $ROOTFS

echo "Getting latest archlinuxarm image..."
echo > $LOG
ALARM=ArchLinuxARM-armv7-latest.tar.gz
wget -O $ALARM http://archlinuxarm.org/os/$ALARM >> $LOG

echo "Extracting ..."
sudo $TAR -xzpf ArchLinuxARM-armv7-latest.tar.gz -C $ROOTFS --warning=none 2>&1 >> $LOG

echo "Building ..."
sudo rm $ROOTFS/etc/resolv.conf 2>&1 >> /dev/null
sudo mkdir -p $ROOTFS/root/.ssh/
sudo touch $ROOTFS/root/.ssh/authorized_keys
sudo cp -vr patches/etc/* $ROOTFS/etc/ >> $LOG
sudo cp -vr patches/usr/* $ROOTFS/usr/ >> $LOG
#sudo cp install.sh  $INITFS/install.sh
#sudo chown root:root $INITFS/install.sh
#sudo chmod 0755 $INITFS/install.sh
sudo cp chroot.sh $ROOTFS/root/
sudo chmod 0755 $ROOTFS/root/chroot.sh
#sudo cp xnbd-client $ROOTFS/usr/local/bin/
#sudo chmod 0755 $ROOTFS/usr/local/bin/xnbd-client
sudo sed -i '/CheckSpace/c\#CheckSpace' $ROOTFS/etc/pacman.conf
sudo cp oc-sync-kernel-modules $INITFS/
sudo cp oc-sync-kernel-modules $ROOTFS/usr/local/bin/

echo "Chrooting ..."
sudo mount --bind /dev ${ROOTFS}/dev
sudo mount --bind /dev/pts ${ROOTFS}/dev/pts
sudo mount -t proc proc ${ROOTFS}/proc
sudo mount -t sysfs sys ${ROOTFS}/sys
sudo mount --bind ${INITFS} ${ROOTFS}/mnt
sudo chroot ${ROOTFS} /bin/bash /root/chroot.sh
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
sudo $TAR -cpf $DST/$IMG . >> $LOG
popd
pushd $INITFS
sudo $TAR -cpf $DST/$iIMG . >> $LOG
popd

envsubst < $FILE_RUN > $DST/$FILE_RUN
chmod +x $DST/$FILE_RUN
envsubst < $FILE_INST > $DST/$FILE_INST
chmod +x $DST/$FILE_INST

sudo rm -rf $ROOTFS
sudo rm -rf $INITFS
echo Finished!

cat << __EOF__
To buil the target server:
  * upload $iIMG, $IMG, $FILE_INST and $FILE_RUN to $DESTINATION_URL
  * create a new C1 instance and add 'INIRD_POST_SHELL=1' tag to it
  * boot, connect to the console, then:
    * wget -O - $DESTINATION_URL/$FILE_INST | sh to install the new instance
    or
    * wget -O - $DESTINATION_URL/$FILE_RUN | sh to unlock and run an installed instance
__EOF__


