#! /bin/bash
# This script partition /dev/nbd0 as
#  1 : / partition, btrfs with 3 subvol : root home data
#  2 : swap 2G
# the it copy the / content to partion 1

echo "I'm a manual installer ;)"

#--- some variables
CONF=/tmp/conf
DISK=/dev/nbd0
CRYPTROOT=cryptroot
CHROOT=/newroot

#--- let's go
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
umount $DISK 2>&1>/dev/null
umount -l $DISK 2>&1>/dev/null
dd if=/dev/zero of=${DISK} bs=1M count=4
cat << EOF
******************************************************************************
Too late now... new $DISK zero'ed !
We're going to FORMAT and CRYPT your root partition on it now
Please keep your passphase SAFE, lose it and you'll lose all your data!
******************************************************************************
EOF

cryptsetup luksFormat ${DISK}

cryptsetup open ${DISK} ${CRYPTROOT}

modprobe btrfs
mkfs.btrfs  /dev/mapper/${CRYPTROOT}
mount /dev/mapper/${CRYPTROOT} ${CHROOT}
btrfs sub create ${CHROOT}/root
btrfs sub create ${CHROOT}/home
btrfs sub create ${CHROOT}/data

#--- XXX : FIXME : how to ge subvolid ???
btrfs sub set-default 257 ${CHROOT}
umount ${CHROOT}

mount -o subvol=root /dev/mapper/${CRYPTROOT} ${CHROOT}
mkdir -p ${CHROOT}/home
mount -o subvol=home /dev/mapper/${CRYPTROOT} ${CHROOT}/home
mkdir -p ${CHROOT}/data
mount -o subvol=data /dev/mapper/${CRYPTROOT} ${CHROOT}/data

echo "Now install to the target system ..."
cd ${CHROOT}
wget -O - $DESTINATION_URL/$IMG | tar -xpf -

cat << __EOF__
Have a look at this new system before reboot
Type exit to go to the new system
__EOF__
sync; sync; sync; exit 



