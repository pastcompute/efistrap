#!/bin/bash

echo
echo 'Running in chroot ...'
echo

MY_HOSTNAME=efistrap

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

export LC_ALL=en_AU.UTF-8
export LANG=en_AU
apt-get install -y locales
printf '%s\n' LANG=en_AU LC_ALL=en_AU.UTF-8 > /etc/default/locale
echo en_AU.UTF-8 UTF-8 >>/etc/locale.gen
echo en_US.UTF-8 UTF-8 >>/etc/locale.gen
locale-gen

# Install all the things
apt-get install -y keyboard-configuration console-setup \
  dosfstools htop git screen vim curl wget man-db net-tools \
  software-properties-common rsync \
  gdisk parted dosfstools zfsutils-linux btrfs-progs bmon iotop \
  ntfs-3g debootstrap bind9-host \
  lm-sensors cryptsetup borgmatic usbutils lsof initramfs-tools \
  lsb-release eject perl-doc ripgrep \
  strace psmisc network-manager sudo \
  openssh-server openssh-client \
  arch-install-scripts

echo RESUME=none > /etc/initramfs-tools/conf.d/noresume.conf

# This step can be quite slow
apt install -y memtest86+ grub-efi-amd64 efibootmgr \
  linux-headers-amd64 linux-image-amd64 firmware-linux-nonfree

# Set a user and password
# and dont inherit the hostname...
echo "$MY_HOSTNAME" > /etc/hostname

cat > /etc/resolv.conf <<EOF
domain lan
search lan
EOF

cat > /etc/hosts <<EOF
127.0.0.1 localhost $MY_HOSTNAME

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

systemctl enable ssh

apt-get clean

mkdir -p /mnt/{c,d,e,f,g,u,x,tmp}

cat > /etc/issue <<EOF
Debian GNU/Linux 11 \n \l

-----------------------------------------------------------------------------
\4 | \d | \t
-----------------------------------------------------------------------------

EOF



echo root:root | chpasswd

useradd -m -s /bin/bash efistrap
usermod -a -G sudo efistrap
echo efistrap:efistrap | chpasswd
