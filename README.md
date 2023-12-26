# Objective

Create a bootable USB drive that has a simple, custom, easily modifiable Debian live system that can be used as custom rescue system or to further run `deboostrap`

## Note 

This tool is for fairly simple cases, my itch to scratch was boot an EFI system fast to run `debootstrap` and/or other scripts with access to various EFI tools.

SysRescue, Kali, Parrot, or a Debian or Ubuntu live image are all worthy and more comprehensive tools.

## Included

- Debian Bookworm with a minimal set of packages and ssh server
- [rEFInd](http://www.rodsbooks.com/refind/)
- [ZFS Boot Menu](https://github.com/zbm-dev/zfsbootmenu)
- [memtest86+](https://memtest.org/readme)
- [Shell_Full (legacy EFI shell)](https://github.com/tianocore/edk2/tree/UDK2018/EdkShellBinPkg/FullShell/X64)

## USB Drive Usage

- copy to the USB drive, any custom scripts you need to do work with after booting the target system
    - dependening on the complexity, either use the ESP FAT32 partition (thus also accessible from Windows or MacOS) or the Debian ext4 partition
- boot to the EFI boot selection menu and boot the USB drive
    - the USB drive will start rEFInd (depending on past use of the system and your USB drive)
- choose `Debian(USB)` from the rEFInd menu to boot to grub and Debian
    - other EFI tools include:
        - legacy Shell_Full.efi (because I was testing this on an older system)
        - memtest86+
        - ZFS Boot Menu (ZBM)
- the ESP FAT32 partition is mounted in the usual location, `/boot/efi`
- the booted Debian has a default NetworkManager setup which should hopefully find a DHCP address on the first ethernet, if any

## USB Creation

- it is recommended to run this in something like `screen` with logging enabled
- fetch the dependencies and any missing apt dependencies needed to complete the build
- insert a disposable USB stick
- run `lsblk` and verify the block device for your USB drive
- build the USB stick
    - specify the block device for the USB drive, e.g. `/dev/sdb`
    - this will wipe the boot block and make a new GPT with two partitions, a FAT32 EFI ESP and an ext4 for Debian
    - when finished, the partitions on the stick are left mounted in case you want to debug or fine tune, along with proc, sys and dev bind mounts
        - `/mnt/efistrap` is the ESP partition
        - `/mnt/efistrad` is the Debian partition
- unmount it
- example sequence:
    ```
    sudo ./apt_dependencies.sh
    ./get_dependencies.sh
    sudo ./usb_create.sh /dev/sdb
    sudo ./usb_eject.sh
    ```

## Customisation before build

- Change the default hostname at the top of `10_bootstrap.sh`
- Change the default passwords / user at the very end of `10_bootstrap.sh`

This could all be much more customisable but I haven't bothered as yet, to customise just edit the shell scripts directly. The installed package list is in [10_bootstrap.sh](/10_bootstrap.sh)

## Debugging

- Mount again using `sudo ./usb_create.sh mount /dev/sdb`
- Enter a chroot using `sudo ./usb_chroot.sh`

## Notes

- The script builds directly onto the target USB - including making kernel modules, etc. Your performance may vary...
- Only x64 EFI is supported
- At the moment the local directory `./dependencies` is created as the current user for fetching dependencies and is assumed writable
- By default this uses a local instance of apt-cacher-ng on port 8889 to cache packages for repeated builds (change port at top of `usb_create.sh`), this is left running as the local user who runs sudo, the pid file is in `apt-cache/pid`
- At the moment the local directory `./apt-cache` is created as the current user and assumed writable
