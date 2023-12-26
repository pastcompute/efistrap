#!/bin/bash

set -euo pipefail

MOUNTPOINT=${MOUNTPOINT:-/mnt/efistrap}
MOUNTPOINT2=${MOUNTPOINT2:-/mnt/efistrad}

mkdir -p "$MOUNTPOINT/EFI/ZBM"
cp dependencies/ZBM.EFI "$MOUNTPOINT/EFI/ZBM/VMLINUZ.EFI"

./usb_chroot.sh cp /boot/memtest86+x64.efi /boot/efi/EFI/refind/tools_x64

mkdir -p "$MOUNTPOINT/EFI/shell"
cp dependencies/Shell_Full.efi "$MOUNTPOINT/EFI/shell"
