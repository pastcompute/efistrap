#!/bin/bash

MOUNTPOINT=${MOUNTPOINT:-/mnt/efistrap}
MOUNTPOINT2=${MOUNTPOINT2:-/mnt/efistrad}

sed -i -e '/GRUB_CMDLINE_LINUX_DEFAULT/ s/quiet//' "$MOUNTPOINT2/etc/default/grub"

cat > "$MOUNTPOINT2/boot/grub/custom.cfg" <<EOF
menuentry "rEFInd" {
        insmod part_gpt
        insmod chain
        set root='(hd1,gpt1)'
        chainloader /EFI/refind/refind_x64.efi
}
menuentry "ZFSBootManager" {
        insmod part_gpt
        insmod chain
        set root='(hd1,gpt1)'
        chainloader /EFI/ZBM/VMLINUZ.EFI
}
menuentry "memtest" {
        insmod part_gpt
        insmod chain
        set root='(hd1,gpt1)'
        chainloader /EFI/refind/tools_x64/memtest86+x64.efi
}
menuentry "EFI shell" {
        insmod part_gpt
        insmod chain
        set root='(hd1,gpt1)'
        chainloader /EFI/shell/Shell_Full.efi
}
EOF

./usb_chroot.sh update-grub
./usb_chroot.sh grub-install \
  --efi-directory=/boot/efi \
  --force-extra-removable --no-nvram --target=x86_64-efi \
  "$TARGET"

# This will create
# /mnt/efistrap/EFI/debian
# /mnt/efistrap/EFI/debian/grubx64.efi
# /mnt/efistrap/EFI/debian/shimx64.efi
# /mnt/efistrap/EFI/debian/mmx64.efi
# /mnt/efistrap/EFI/debian/fbx64.efi
# /mnt/efistrap/EFI/debian/BOOTX64.CSV
# /mnt/efistrap/EFI/debian/grub.cfg

# So now we have 
# /mnt/efistrap/EFI/debian
# /mnt/efistrap/EFI/refind

./usb_chroot.sh cp /boot/memtest86+x64.efi /boot/efi/EFI/refind/tools_x64

# shellcheck disable=SC2028
echo 'efibootmgr -c -l \\EFI\\debian\\grubx64.efi -L grub' > "$MOUNTPOINT/debian-efi-vars.txt"
