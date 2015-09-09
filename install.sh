#! /bin/bash
# This script partition /dev/nbd0 as
#  1 : / partition, btrfs with 3 subvol : root home data
#  2 : swap 2G
# the it copy the / content to partion 1

echo "I'm a manual installer ;)"
/usr/sbin/sshd
echo "SSHD started!"

#--- some variables
CONF=/tmp/conf
DISK=/dev/nbd0
CRYPTROOT=cryptroot
CHROOT=/mnt

#--- let's go
curl http://$METADATA_IP/conf > $CONF
NBD_IP=$(grep VOLUMES_0_EXPORT_URI $CONF|cut -d '/' -f 3|cut -d ':' -f 1)
NBD_PORT=$(grep VOLUMES_0_EXPORT_URI $CONF|cut -d '/' -f 3|cut -d ':' -f 2)

echo "Mounting $NBD_IP:$NBD_PORT to $DISK ..."
nbd-client $NBD_IP $NBD_PORT /dev/nbd0
cat << EOF
******************************************************************************
*** ATTENTION : this will erase ALL CONTENTS on ${DISK}
*** ARE YOU SUR ???
******************************************************************************
EOF
select rep in "YES" "NO" ; do 
	case $rep in
		YES ) break;;
		NO ) exit 0 ;;
	esac
done

echo "Formating disk ${DISK}"
parted -s ${DISK} mklabel msdos
parted -- ${DISK} unit MB mkpart primary linux-swap 2 2048
parted -- ${DISK} unit MB mkpart primary 2048 -0
dd if=/dev/zero of=${DISK}2 bs=1M count=10
cat << EOF
******************************************************************************
Too late now... new partition created !
We're going to FORMAT and CRYPT your root partition on ${DISK} 
Please keep your passphase SAFE, lose it and you'll lose all your data!
******************************************************************************
EOF

cryptsetup luksFormat ${DISK}2

cryptsetup open ${DISK}2 ${CRYPTROOT}

mkfs.btrfs  /dev/mapper/${CRYPTROOT}
mount /dev/mapper/${CRYPTROOT} /mnt
btrfs sub create ${CHROOT}/root
btrfs sub create ${CHROOT}/home
btrfs sub create ${CHROOT}/data
#--- XXX : FIXME : how to ge subvolid ???
btrfs sub set-default 6 /mnt
umount ${CHROOT}

mount -o subvol=root /dev/mapper/${CRYPTROOT} ${CHROOT}
mkdir -p ${CHROOT}/home
mount -o subvol=home /dev/mapper/${CRYPTROOT} ${CHROOT}/home

echo "Now install to the target system ..."
cd /
tar -cpf - . | tar -xpf -C /mnt
mv /usr/sbin/init /usr/sbin/init.for.install
mv /usr/sbin/init.orig /usr/sbin/init

echo "Have a look at this new system before reboot, don't forget to reset server's TAG"
/bin/bash

