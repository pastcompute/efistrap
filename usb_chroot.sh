#!/bin/bash

MOUNTPOINT=${MOUNTPOINT:-/mnt/efistrap}
MOUNTPOINT2=${MOUNTPOINT2:-/mnt/efistrad}
#set -x
function is_mount() {
  grep -q -E "^\S+\s${1}\s" /proc/mounts
}

is_mount $MOUNTPOINT2 || { echo "Not mounted!" ; exit 1; }

mkdir -p $MOUNTPOINT2/{proc,sys,dev}

is_mount $MOUNTPOINT2/proc || mount -v -t proc proc "$MOUNTPOINT2/proc"
is_mount $MOUNTPOINT2/sys || mount -v -t sysfs sys "$MOUNTPOINT2/sys"
is_mount $MOUNTPOINT2/dev || mount -v -B /dev "$MOUNTPOINT2/dev"
is_mount $MOUNTPOINT2/dev/pts || mount -v -t devpts pts "$MOUNTPOINT2/dev/pts"

mkdir -p $MOUNTPOINT2/boot/efi
is_mount $MOUNTPOINT2/boot/efi || mount -v -B "$MOUNTPOINT" $MOUNTPOINT2/boot/efi

echo 'Acquire::http { Proxy "http://127.0.0.1:8889"; }' | sudo tee -a "$MOUNTPOINT2/etc/apt/apt.conf.d/proxy"

function atexit_handler() {
  rm -f "$MOUNTPOINT2/etc/apt/apt.conf.d/proxy"
}
trap atexit_handler EXIT

if [ "$1" == "bootstrap" ] ; then
  mkdir -p "$MOUNTPOINT2/root"
  cp 10_bootstrap.sh "$MOUNTPOINT2/root"
  chmod +x "$MOUNTPOINT2/root/10_bootstrap.sh"
  chroot "$MOUNTPOINT2" /bin/bash -c /root/10_bootstrap.sh
else
  set -x
  chroot "$MOUNTPOINT2" "${@}"
fi

