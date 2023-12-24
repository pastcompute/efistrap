#!/bin/bash

echo
echo 'Running in chroot ...'
echo

export DEBIAN_FRONTEND=noninteractive

apt update
apt install apt-transport-https ca-certificates -y
cat > /etc/apt/sources.list <<EOF
deb https://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb https://security.debian.org/debian-security/ bookworm-security contrib main non-free non-free-firmware
deb https://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb https://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware
EOF
apt update

# FIXME debconf for en_AU

export LC_ALL=en_AU.UTF-8
export LANG=en_AU
apt-get install -y locales
printf '%s\n' LANG=en_AU LC_ALL=en_AU.UTF-8 > /etc/default/locale
echo en_AU.UTF-8 UTF-8 >>/etc/locale.gen
echo en_US.UTF-8 UTF-8 >>/etc/locale.gen
locale-gen

# Should choose default US keyboard
apt install -y keyboard-configuration console-setup -y
apt install -y dosfstools htop git screen vim curl wget man-db
tasksel install ssh-server
apt install -y linux-headers-amd64 linux-image-amd64 firmware-linux-nonfree memtest86+ grub-efi-amd64

apt install network-manager sudo

# Set a user and password
# and dont inherit the hostname...
echo 'efistrap' > /etc/hostname

echo root:root | chpasswd

useradd -m -s /bin/bash efistrap
usermod -a -G sudo efistrap
echo efistrap:efistrap | chpasswd

systemctl enable ssh
