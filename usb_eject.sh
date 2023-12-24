#!/bin/bash

MOUNTPOINT=/mnt/efistrap
MOUNTPOINT2=/mnt/efistrad

for x in 1 2 3 4 ; do
umount "$MOUNTPOINT2/boot/efi"
umount "$MOUNTPOINT2/proc"
umount "$MOUNTPOINT2/sys"
umount "$MOUNTPOINT2/dev/pts"
umount "$MOUNTPOINT2/dev"
umount $MOUNTPOINT2
umount $MOUNTPOINT
done
sync
