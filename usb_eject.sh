#!/bin/bash

MOUNTPOINT=/mnt/efistrap
MOUNTPOINT2=/mnt/efistrad

function umount_all_try() {
  umount "$MOUNTPOINT2/boot/efi"
  umount "$MOUNTPOINT2/proc"
  umount "$MOUNTPOINT2/sys"
  umount "$MOUNTPOINT2/dev/pts"
  umount "$MOUNTPOINT2/dev"
  umount $MOUNTPOINT2
  umount $MOUNTPOINT
}

for x in 1 2 3 4 5 ; do
  umount_all_try > /dev/null 2>&1
done
umount_all_try
sync
