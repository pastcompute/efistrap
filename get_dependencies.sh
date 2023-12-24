#!/bin/bash

set -e
mkdir -p dependencies
cd dependencies
wget --content-disposition https://sourceforge.net/projects/refind/files/0.14.0.2/refind-bin-0.14.0.2.zip/download
wget --content-disposition 'https://github.com/tianocore/edk2/blob/UDK2018/EdkShellBinPkg/FullShell/X64/Shell_Full.efi?raw=true'
wget -O ZBM.EFI https://get.zfsbootmenu.org/efi
