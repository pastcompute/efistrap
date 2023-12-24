#!/bin/bash

TARGET="$1"

EFISTRAP_DELAY=${EFISTRAP_DELAY:-5}

MOUNTPOINT=/mnt/efistrap
MOUNTPOINT2=/mnt/efistrad

export MOUNTPOINT
export MOUNTPOINT2

if [ "$TARGET" == "mount" ] ; then
  TARGET="$2"
  test -z "$TARGET" && { echo "Specify dev" ; exit 1; }
  set -ex
  mount "${TARGET}1" $MOUNTPOINT
  mount "${TARGET}2" $MOUNTPOINT2
  exit 0
fi
if [ "$TARGET" == "umount" ] ; then
  for x in 1 2 3 4 ; do
    umount "$MOUNTPOINT2/boot/efi"
    umount "$MOUNTPOINT2/proc"
    umount "$MOUNTPOINT2/sys"
    umount "$MOUNTPOINT2/dev/pts"
    umount "$MOUNTPOINT2/dev"
    umount $MOUNTPOINT2
    umount $MOUNTPOINT
  done
  exit 0
fi

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

if grep -q -E '^'$MOUNTPOINT'\s' /proc/mounts ; then
  echo "Already mounted: $MOUNTPOINT"
  exit 1
fi
if grep -q -E '^'$MOUNTPOINT2'\s' /proc/mounts ; then
  echo "Already mounted: $MOUNTPOINT2"
  exit 1
fi

# Anything else (directory, etc) should just fail
if grep -E '^/dev/[^0-9]*[1-9][0-9]*' -q <<<"$TARGET" ; then
  echo Cowardly refusing to work on what is apparently a partition
  exit 1
elif test -L "$TARGET"; then 
  echo Cowardly refusing to work through a symlink
  exit 1
elif test -b "$TARGET" ; then
  echo 
  echo "WARNING!!! THIS WILL NUKE PRESUMED USB DRIVE: $TARGET"
  echo
  echo "Press Ctrl+C before $EFISTRAP_DELAY seconds to cancel..."
  echo
elif test -f "$TARGET"; then 
  echo 
  echo "WARNING!!! THIS WILL REPLACE FILE: $TARGET"
  echo
  echo "Press Ctrl+C before $EFISTRAP_DELAY seconds to cancel..."
  echo
elif test -e "$TARGET"; then 
  echo Cowardly refusing to work on not a file or block device
  exit 1
else
  echo 'File does not exist - run `truncate -s 4G '"$TARGET"'` first...'
  exit 1
fi

# We want to fail if the target is mounted, _and_ if we are silly enough to use a non standard symlink
# We could do some funky stuff to check if it is mounted, resolving symlinks etc
# https://stackoverflow.com/questions/8808415/using-bash-to-tell-whether-or-not-a-drive-with-a-given-uuid-is-mounted
# But that is too hard for now

# This is redundant as we wont target a partition
if grep -E "^$TARGET\s" -q /proc/mounts ; then
  echo "$TARGET is mounted! Cancelling..."
  exit 1
fi

FOUND_USB=0
for x in /dev/disk/by-id/usb-* ; do
  if [ "$(realpath -e "$x")" == "$TARGET" ] ; then
    FOUND_USB=1
    echo "$TARGET is a USB drive"
    break
  fi
done
if [ $FOUND_USB -eq 0 ] ; then
  for x in /dev/disk/by-id/* ; do
  if [ "$(realpath -e "$x")" == "$TARGET" ] ; then
    echo
    echo "Warning!! $TARGET is NOT a USB drive!"
    echo
    break
  fi
  done
fi
echo
echo "Continuing in $EFISTRAP_DELAY seconds..."
sleep "$EFISTRAP_DELAY"

# We expect this will fail if any partitions are mounted or device is otherwise open
# So it should protect the operating system drive
wipefs -a "$TARGET"

sgdisk -o -n 1:1M:+1G -t 1:0700 -c 1:EFI -n 2:+1M:0 -t 2:8300 -c 2:debian "$TARGET"

mkfs.vfat -n "efistrap" "${TARGET}1"
wipefs -a "${TARGET}2"
mkfs.ext4 -L debian "${TARGET}2"

mkdir -p $MOUNTPOINT $MOUNTPOINT2
mount "${TARGET}1" $MOUNTPOINT
mount "${TARGET}2" $MOUNTPOINT2

./05_refind.sh

debootstrap bookworm "$MOUNTPOINT2"

./usb_chroot.sh bootstrap

./15_grub.sh

mkdir -p "$MOUNTPOINT/EFI/ZBM"
cp dependencies/ZBM.EFI "$MOUNTPOINT/EFI/ZBM/VMLINUZ.EFI"

UUID1=$(blkid -o export -s UUID "${TARGET}1" 2> /dev/null | grep -e ^UUID=)
UUID2=$(blkid -o export -s UUID "${TARGET}2" 2> /dev/null | grep -e ^UUID=)

cat > "$MOUNTPOINT2/etc/fstab" <<EOF
$UUID2 / auto defaults,noatime 0 0
$UUID1 /boot/efi auto defaults 0 0
EOF

# Make refind the default
cp "$MOUNTPOINT/EFI/BOOT/BOOTX64.EFI" "$MOUNTPOINT/EFI/BOOT/BOOTX64.EFI.grub"
cp "$MOUNTPOINT/EFI/refind/refind_x64.efi" "$MOUNTPOINT/EFI/BOOT/BOOTX64.EFI"
