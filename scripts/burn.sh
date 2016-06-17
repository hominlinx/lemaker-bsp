#!/bin/bash

IMG_FILE="bananapi.img"
echo
echo "#####################"
echo "# Creating img file #"
echo "#####################"
echo
dd if=/dev/zero of=${IMG_FILE} bs=1M count=256
LOOP_DEV=`sudo losetup -f --show ${IMG_FILE}`
LOOP_DEV_NAME=`basename ${LOOP_DEV}`
LOOP_PART_BOOT="/dev/mapper/${LOOP_DEV_NAME}p1"
LOOP_PART_SYS="/dev/mapper/${LOOP_DEV_NAME}p2"
echo
echo "#########################"
echo " +>${LOOP_DEV} "
echo " +->${LOOP_PART_BOOT} "
echo " +->${LOOP_PART_SYS} "
echo "#########################"
echo

echo
echo "#############################"
echo "# Creating partitions table #"
echo "#############################"
echo

echo -e "o\nn\np\n1\n2048\n+20M\nn\np\n2\n43008\n\np\nt\n1\nc\np\nw" | sudo fdisk ${LOOP_DEV}

sudo fdisk -l ${LOOP_DEV}

echo
echo "########################"
echo "# Creating filesystems #"
echo "########################"
echo
sudo kpartx -av ${LOOP_DEV}
sudo mkfs.vfat ${LOOP_PART_BOOT} -I -F 32 -n boot
sudo mkfs.ext4 -O ^has_journal -E stride=2,stripe-width=1024 -b 4096 "${LOOP_PART_SYS}" -L system
sync

echo
echo "##########################"
echo "# Burning the bootloader #"
echo "##########################"
echo
sudo dd if=/dev/zero of=${LOOP_DEV} bs=1k count=1023 seek=1
sudo dd if=$PWD"/build/BananaPi_hwpack/bootloader/u-boot-sunxi-with-spl.bin" of=${LOOP_DEV} bs=1024 seek=8
sync

echo
echo "######################"
echo "# Copying boot files #"
echo "######################"
echo
if [[ -e "/mnt/boot" ]];then
    sudo rm /mnt/boot -rf
fi
sudo mkdir /mnt/boot
sudo mount -t vfat "${LOOP_PART_BOOT}" /mnt/boot
sudo cp $PWD"/build/BananaPi_hwpack/kernel/uImage" /mnt/boot
sudo cp $PWD"/build/BananaPi_hwpack/kernel/script.bin" /mnt/boot
#sudo cp build/.config /mnt
sync

ls -al /mnt/boot
sudo umount /mnt/boot

echo
echo "##################"
echo "# Copying rootfs #"
echo "##################"
echo
sudo mount -t ext4 "${LOOP_PART_SYS}" /mnt
sudo rm -rf /mnt/*
sudo cp -r $PWD/build/BananaPi_hwpack/rootfs/* /mnt
sudo mknod /mnt/dev/console c 5 1
sudo mknod /mnt/dev/null c 1 3
if [ -f /mnt/README.md ]; then
        sudo rm -rf /mnt/README.md
fi
sync

#echo
#echo "############################################"
#echo "# Creating /proc, /sys, /mnt, /tmp & /boot #"
#echo "############################################"
#echo
#sudo mkdir -p /mnt/proc
#sudo mkdir -p /mnt/sys
#sudo mkdir -p /mnt/mnt
#sudo mkdir -p /mnt/tmp
#sudo mkdir -p /mnt/boot
#sync

ls -al /mnt
sudo umount /mnt



sudo kpartx -d ${LOOP_DEV}
sudo losetup -d ${LOOP_DEV}
