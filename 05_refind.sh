#!/bin/bash

MOUNTPOINT=${MOUNTPOINT:-/mnt/efistrap}
MOUNTPOINT2=${MOUNTPOINT2:-/mnt/efistrad}

REFIND_VER=0.14.0.2
REFIND_ZIP=refind-bin-${REFIND_VER}.zip
REFIND_BIN=refind-bin-${REFIND_VER}

TEMPDIR=/tmp/$$

set -euo pipefail

rm -rf "$TEMPDIR"
mkdir -p "$TEMPDIR"
unzip -d "$TEMPDIR" dependencies/"$REFIND_ZIP"

mkdir -p "$MOUNTPOINT/EFI"
cp -r "$TEMPDIR/$REFIND_BIN/refind" "$MOUNTPOINT/EFI"
rm -rf "$TEMPDIR"

mkdir -p "$MOUNTPOINT/EFI/shell"
cp dependencies/Shell_Full.efi "$MOUNTPOINT/EFI/shell"

pushd "$MOUNTPOINT/EFI/refind" > /dev/null

rm -rf drivers*/reiserfs*
rm -rf drivers_aa64 tools_aa64
# TODO: Consider removing ia32

cp refind.conf-sample refind.conf
echo textonly >> refind.conf

cat >> refind.conf <<EOF
menuentry Debian(USB) {
    loader /EFI/debian/grubx64.efi
    icon /EFI/refind/icons/os_debian.png
}
menuentry Memtest {
    loader /EFI/refind/tools_x64/memtest86+x64.efi
    icon /EFI/refind/icons/tool_shell.png
}
menuentry ZBM {
    loader /EFI/ZBM/VMLINUZ.EFI
    icon /EFI/refind/icons/tool_rescue.png
}
menuentry Shell {
    loader /EFI/shell/shell_full.efi
    icon /EFI/refind/icons/tool_efi.png
}
EOF

popd > /dev/null

# shellcheck disable=SC2028
echo 'efibootmgr -c -l \\EFI\\refind\\refind_x64.efi -L rEFInd' > "$MOUNTPOINT/refind-efi-vars.txt"
