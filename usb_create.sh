#!/bin/bash

TARGET="$1"

CACHEPROXY_PORT=8889
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

echo Checking apt-cacher-ng
mkdir -p apt-cache/{apt-cacher-ng,cache}
cat > apt-cache/apt-cacher-ng/my.conf <<EOF
CacheDir: $(pwd)/apt-cache/cache
LogDir: $(pwd)/apt-cache/log
SocketPath: $(pwd)/apt-cache/socket
Port: $CACHEPROXY_PORT
BindAddress: 127.0.0.1
ExThreshold: 30
PidFile: $(pwd)/apt-cache/pid
EOF

# Hacky but gets the job done
PROXY_PID=$(test -e "$(pwd)/apt-cache/pid" && cat "$(pwd)/apt-cache/pid") || true
if test -n "${PROXY_PID:-}" && ps -f "${PROXY_PID}" > /dev/null ; then
  echo "Found running apt-cacher-ng"
else
  rm -f "$(pwd)/apt-cache/pid"
  echo "Starting apt-cacher-ng"
  if [ -n "${SUDO_USER:-}" ] ; then
    runuser -u "${SUDO_USER:-USER}" -- /sbin/apt-cacher-ng -v -c apt-cache/apt-cacher-ng
  else
    /sbin/apt-cacher-ng -v -c apt-cache/apt-cacher-ng
  fi
fi
echo "apt-cacher-ng pid=$(cat "$(pwd)/apt-cache/pid")"

# We expect this will fail if any partitions are mounted or device is otherwise open
# So it should protect the operating system drive
# If not run with sudo, at this point we will also crash out, wipefs won't be in PATH
wipefs -a "$TARGET"

sgdisk -o -n 1:1M:+1G -t 1:0700 -c 1:EFI -n 2:+1M:0 -t 2:8300 -c 2:debian "$TARGET"

mkfs.vfat -n "efistrap" "${TARGET}1"
wipefs -a "${TARGET}2"
mkfs.ext4 -L debian "${TARGET}2"

mkdir -p $MOUNTPOINT $MOUNTPOINT2
mount "${TARGET}1" $MOUNTPOINT
mount "${TARGET}2" $MOUNTPOINT2

./05_refind.sh

# Examples of using apt-cacher-ng:
# echo 'Acquire::http { Proxy "http://127.0.0.1:8889"; }' | sudo tee -a /etc/apt/apt.conf.d/proxy
# http://http://127.0.0.1:8889/us.archive.ubuntu.com/ubuntu/

debootstrap bookworm "$MOUNTPOINT2" http://127.0.0.1:$CACHEPROXY_PORT/deb.debian.org/debian/

./usb_chroot.sh bootstrap

./15_grub.sh

./20_fstab.sh

./25_efi_extras.sh

./30_default_boot.sh

echo -e "\nNote: apt-cacher-ng running with pid=$(pwd)/apt-cache/pid\n"
