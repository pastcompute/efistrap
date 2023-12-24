#!/bin/bash

MOUNTPOINT=${MOUNTPOINT:-/mnt/efistrap}
MOUNTPOINT2=${MOUNTPOINT2:-/mnt/efistrad}

UUID1=$(blkid -o export -s UUID "${TARGET}1" 2> /dev/null | grep -e ^UUID=)
UUID2=$(blkid -o export -s UUID "${TARGET}2" 2> /dev/null | grep -e ^UUID=)

cat > "$MOUNTPOINT2/etc/fstab" <<EOF
$UUID2 / auto defaults,noatime 0 0
$UUID1 /boot/efi auto defaults 0 0
EOF
