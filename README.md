Archlinux image on Scaleway [![Build Status](https://travis-ci.org/scaleway/image-archlinux.svg?branch=master)](https://travis-ci.org/scaleway/image-archlinux)
===========================

Scripts to build my personal ArchlinuxARM image on Scaleway with dm-encrypted root file system

This image DOES NOT use the officiel [Image Tools](https://github.com/scaleway/image-tools). Instead it's based on the official [ArchLinuxArm](http://archlinuxarm.org/) image.

<img src="http://archlinuxarm.org/sites/default/files/wikilogo_0_0.png" />

---

**This image is meant to be used on a C1 server.**

This tool will build 2 images:

  * root file system.tar is the official archlinuxarm's one, with 2 addtions:
    * you have to put one or more ssh public keys in keys/ folder. It will grant you root access to the destination image
    * it'll generate ssh host keys so you don't have to blindly trust at first ssh connect

  * init file system.tar is the manual installer, it'll have all the necessary to let you format/install the previous image on a dm-encrypted file system

---

Build your images
----------

You will nedd the following:

* A working archlinuxarm host, like a scalway's C1 instance, let's call it ``SOURCE``
* A C1 instance, where you want to install the ``TARGET`` system
* A http server, reachable by the ``TARGET`` and can host the images at ``URL``

To build:

    git clone https://github.com/juju2013/scaleway-image-archlinux
    cd scaleway-image-archlinux
    DESTINATION_URL=URL ./build.sh
    scp *.tar YOUR_HTTP_SERVER:/URL

Install your images
-----------

  * Create your ``TARGET`` instance
  * Add ``INITRD_POST_SHELL=1`` to TAGS
  * Fire it up
  * Connect to console and wait for initrd's shell, then


    wget -O - URL/your-init.tar | tar xpf -
    ./oc-sync-kernel-modules
    echo format c: here
    dd if=/dev/zero of=/dev/nbd0 bs=1M count=1024
    cryptsetup luksFormat /dev/nbd0
    cryptsetup open /dev/nbd0 cryptroot
    mkfs.btrfs /dev/nbd0
    mount /dev/mapper/cryptroot /newroot
    echo install the target system here
    cd /newroot
    wget -O - URL/your-target.tar | tar xpf -
    sync; sync; sync; exit


Tada! You get a new dm-encrypted, btrfs based arch linux sytem with your own ssh key now !

Boot and reboot
-------
As the file system is encrypted and no descryption key is stored locally, at each boot, you'll need to coneect to the console and run this to finish the boot:


    wget -O - UR/your-init.tar | tar xpf -
    ./oc-sync-kernel-modules
    cryptsetup open /dev/nbd0 cryptroot
    mount /dev/mapper/cryptroot /newroot
    exit



---

Notes
-----
There's many reasons that one would encrypt the whole system, but it's not (and by far) bullet proof. For instance, you don't have the control of the kernel nor the initrd, which make it very easy to backdoor the whole system by - let's say, any 3 letters agencies, Gvt's or employees of scaleway if they want.

---

Have fun!
