#!/bin/bash

set -euo pipefail

MOUNTPOINT=${MOUNTPOINT:-/mnt/efistrap}
MOUNTPOINT2=${MOUNTPOINT2:-/mnt/efistrad}

# Make refind the default
cp "$MOUNTPOINT/EFI/BOOT/BOOTX64.EFI" "$MOUNTPOINT/EFI/BOOT/BOOTX64.EFI.grub"
cp "$MOUNTPOINT/EFI/refind/refind_x64.efi" "$MOUNTPOINT/EFI/BOOT/BOOTX64.EFI"
