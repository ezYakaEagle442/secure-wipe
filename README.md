# Pre-Req

This repository provides a tool to overwrite a USB-Drive data with random patterns multiple times.

- To Mount Disk : [https://learn.microsoft.com/en-us/windows/wsl/wsl2-mount-disk](https://learn.microsoft.com/en-us/windows/wsl/wsl2-mount-disk)
- To mount USB Drives : [https://learn.microsoft.com/en-us/windows/wsl/connect-usb](https://learn.microsoft.com/en-us/windows/wsl/connect-usb)

Credits:  [https://www.youtube.com/watch?v=iyBfQXmyH4o]()

```bash
VM_LINUX_PATH="/mnt/c/PIN/Tools/WSL/vmlinux"
echo "VM_LINUX_PATH $VM_LINUX_PATH"

# If If you have mounted an NTFS-formatted USB drive
# sudo mount -t drvfs D: /mnt/d

# for FAT32
D=$(powershell.exe -NoProfile -ExecutionPolicy Bypass "GET-CimInstance -query 'SELECT * from Win32_DiskDrive'")
echo "$D"
```

```console
DeviceID           Caption                          Partitions Size          Model
--------           -------                          ---------- ----          -----
\\.\PHYSICALDRIVE1 Multiple Card  Reader USB Device 1          1019934720    Multiple Card  Reader USB Device
\\.\PHYSICALDRIVE0 MTFDKBA1T0QFM-1BD1AABGB          5          1024203640320 MTFDKBA1T0QFM-1BD1AABGB
```

```bash
USB_IPD_WIN_VERSION=4.4.0
USB_IPD_WIN_URL="https://github.com/dorssel/usbipd-win/releases/download/v$USB_IPD_WIN_VERSION/usbipd-win_$USB_IPD_WIN_VERSION.msi"
echo "Download $USB_IPD_WIN_URL and run it"
```

Run PowserShell as admin
```bash
usbipd list
$BUS_ID="7-2" # example in my case, take the right one for you
usbipd bind --busid $BUS_ID
usbipd attach --wsl --busid $BUS_ID
```

```console
PS C:\Users\XXX> usbipd attach --wsl --busid $BUS_ID
usbipd: info: Using WSL distribution 'Ubuntu-24.04' to attach; the device will be available in all WSL 2 distributions.
usbipd: info: Detected networking mode 'nat'.
usbipd: info: Using IP address 172.25.80.1 to reach the host.
```


From WSL
```bash
# see also for fun: https://techcommunity.microsoft.com/blog/modernworkappconsult/connecting-a-usb-printer-device-to-wsl-2/3173112
sudo apt install usbutils
lsusb
# in this case the USB Drive is : "Alcor Micro Corp. Multi Flash Reader"
```


```console
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 001 Device 002: ID 058f:6366 Alcor Micro Corp. Multi Flash Reader
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
```

```bash
# https://github.com/microsoft/WSL2-Linux-Kernel/blob/master/Microsoft/config-wsl
# # CONFIG_USB_SUPPORT is not set

# The USB Drivers are at: https://github.com/microsoft/WSL2-Linux-Kernel/tree/master/drivers/usb

# https://github.com/microsoft/WSL2-Linux-Kernel/releases/tag/linux-msft-wsl-5.15.167.4

# Identifying the filesystem type
#ls -al /dev/sd*
#lsblk
#blkid "\\.\PHYSICALDRIVE1"

OS_VER=$(uname -r | sed 's/-microsoft-standard-WSL2//')
echo "OS version: $OS_VER" #ex: 5.15.167.4

git clone -b "linux-msft-wsl-$OS_VER" "https://github.com/microsoft/WSL2-Linux-Kernel.git" "$OS_VER-microsoft-standard"
cd "$OS_VER-microsoft-standard"

# Check https://github.com/microsoft/WSL2-Linux-Kernel/blob/linux-msft-wsl-5.15.167.4/arch/x86/configs/config-wsl
cp /proc/config.gz config.gz
sudo gunzip config.gz
sudo mv config .config
ls -al 

# Install required packages
sudo apt update
sudo apt install libncurses-dev
sudo apt install libncurses6
sudo apt install flex -y
sudo apt install bison -y
sudo apt install build-essential -y
sudo apt install libssl-dev libelf-dev -y
sudo apt upgrade binutils 

# OpenSSL looks like a pre-req
sudo apt install openssl -y
openssl version

# Check pre-req
dpkg -l | grep -E 'libelf|libssl|flex|bison'

######################################################################################
ls -al ./drivers/usb # | grep CONFIG_USB_SUPPORT
cat ./Microsoft/config-wsl | grep CONFIG_USB_SUPPORT
cat ./Microsoft/config-wsl | grep CONFIG_USB_SUPPORT
cat ./arch/x86/configs/config-wsl | grep CONFIG_USB_SUPPORT

cat ./Microsoft/config-wsl | grep CONFIG_X86_X32
cat ./Microsoft/config-wsl | grep CONFIG_IA32_EMULATION=y
cat ./Microsoft/config-wsl | grep CONFIG_COMPAT_32=y
cat ./Microsoft/config-wsl | grep CONFIG_COMPAT=y
cat ./Microsoft/config-wsl | grep CONFIG_COMPAT_FOR_U64_ALIGNMENT=y
cat ./Microsoft/config-wsl | grep CONFIG_SYSVIPC_COMPAT=y

sed -i 's/CONFIG_X86_X32=y/CONFIG_X86_X32=n/' ./Microsoft/config-wsl
sed -i 's/CONFIG_IA32_EMULATION=y/CONFIG_IA32_EMULATION=n/' ./Microsoft/config-wsl
sed -i 's/CONFIG_COMPAT_32=y/CONFIG_COMPAT_32=n/' ./Microsoft/config-wsl
sed -i 's/CONFIG_COMPAT=y/CONFIG_COMPAT=n/' ./Microsoft/config-wsl
sed -i 's/CONFIG_COMPAT_FOR_U64_ALIGNMENT=y/CONFIG_COMPAT_FOR_U64_ALIGNMENT=n/' ./Microsoft/config-wsl
sed -i 's/CONFIG_SYSVIPC_COMPAT=y/CONFIG_SYSVIPC_COMPAT=n/' ./Microsoft/config-wsl

cat ./Microsoft/config-wsl | grep CONFIG_X86_X32=n
cat ./Microsoft/config-wsl | grep CONFIG_IA32_EMULATION=n
cat ./Microsoft/config-wsl | grep CONFIG_COMPAT_32=n
cat ./Microsoft/config-wsl | grep CONFIG_COMPAT=n
cat ./Microsoft/config-wsl | grep CONFIG_COMPAT_FOR_U64_ALIGNMENT=n
cat ./Microsoft/config-wsl | grep CONFIG_SYSVIPC_COMPAT=n

cat ./Microsoft/config-wsl | grep CONFIG_64BIT=y
cat ./Microsoft/config-wsl | grep CONFIG_X86_64=y
cat ./Microsoft/config-wsl | grep CONFIG_X86=y

######################################################################################

cat .config | grep CONFIG_USB_SUPPORT
cat ./arch/x86/configs/config-wsl | grep CONFIG_USB_SUPPORT

cat .config | grep CONFIG_X86_X32
cat .config | grep CONFIG_IA32_EMULATION=y
cat .config | grep CONFIG_COMPAT_32=y
cat .config | grep CONFIG_COMPAT=y
cat .config | grep CONFIG_COMPAT_FOR_U64_ALIGNMENT=y
cat .config | grep CONFIG_SYSVIPC_COMPAT=y

sed -i 's/CONFIG_X86_X32=y/CONFIG_X86_X32=n/' .config
sed -i 's/CONFIG_IA32_EMULATION=y/CONFIG_IA32_EMULATION=n/' .config
sed -i 's/CONFIG_COMPAT_32=y/CONFIG_COMPAT_32=n/' .config
sed -i 's/CONFIG_COMPAT=y/CONFIG_COMPAT=n/' .config
sed -i 's/CONFIG_COMPAT_FOR_U64_ALIGNMENT=y/CONFIG_COMPAT_FOR_U64_ALIGNMENT=n/' .config
sed -i 's/CONFIG_SYSVIPC_COMPAT=y/CONFIG_SYSVIPC_COMPAT=n/' .config

cat .config | grep CONFIG_X86_X32=n
cat .config | grep CONFIG_IA32_EMULATION=n
cat .config | grep CONFIG_COMPAT_32=n
cat .config | grep CONFIG_COMPAT=n
cat .config | grep CONFIG_COMPAT_FOR_U64_ALIGNMENT=n
cat .config | grep CONFIG_SYSVIPC_COMPAT=n

cat .config | grep CONFIG_64BIT=y
cat .config | grep CONFIG_X86_64=y
cat .config | grep CONFIG_X86=y

######################################################################################

make menuconfig
# Enter to Device Drivers / USB Support / press 'Y'
# Also DISABLE ANY refernce to the # Binary Emulations CONFIG_IA32_EMULATION 
# ==> Go to Processor type and features, ensure x32 ABI is disabled , 

# if your station runs AMD Ryzen, the check :
# 'AMD ACPI2Platform devices support'
# AMD Secure Memory Encryption (SME) support
# also Check Power management and ACPI options 

# In Networking support / network options /  Network packet filtering framework (Netfilter) / Core Netfilter / Netfilter Xtables support (required for ip_tables) 

# In Networking support / network options /  Network packet filtering framework (Netfilter) / Core Netfilter / set target and match support 

# | / DISABLE xt_HL  / Xtables targets & Xtables matches

# troubleshoot
#ls -al ./include/linux/netfilter_ipv4/ipt_ECN.h # /!\ File is MISSING !
ls -al  net/ipv4/netfilter/ipt_ECN.c
ls -al  net/ipv4/netfilter/ipt_ECN.h # is MISSING as net/ipv4/netfilter/ipt_ECN.c DOES exist


# Hotfix :
# Définir le chemin du fichier
FILE="net/ipv4/netfilter/ipt_ECN.h"

# Vérifier si le fichier existe déjà
if [ -f "$FILE" ]; then
    echo "Le fichier $FILE existe déjà."
else
    echo "Le fichier $FILE n'existe pas, il sera créé."
fi

# Ajouter le contenu nécessaire dans le fichier
cat <<EOL > "$FILE"
#ifndef _IPT_ECN_H
#define _IPT_ECN_H

#include <linux/types.h>
#include <linux/netfilter.h>

// Définir des structures manquantes
struct ipt_ECN_info {
    __u8 operation;
    __u8 ip_ect;
    union {
        struct {
            __u8 ece;
            __u8 cwr;
        } tcp;
    } proto;
};

// Constantes manquantes
#define IPT_ECN_IP_MASK 0x03
#define IPT_ECN_OP_SET_ECE 0x01
#define IPT_ECN_OP_SET_CWR 0x02
#define IPT_ECN_OP_SET_IP  0x04

#endif // _IPT_ECN_H
EOL
clear
echo "Le contenu a été ajouté au fichier $FILE."


grep -rnw include/ -e "struct ipt_ECN_info"
# ls -al net/netfilter/xt_HL.o is MISSING
grep CONFIG_NETFILTER_XT_TARGET_HL=y  .config
grep CONFIG_NETFILTER_XT_MATCH_HL=y  .config
find . -name '*xt_HL*'
find ./net -name '*xt*'
modinfo xt_HL
lsmod | grep xt_HL

sed -i 's/CONFIG_NETFILTER_XT_TARGET_HL=y/CONFIG_NETFILTER_XT_TARGET_HL=n/' .config
sed -i 's/CONFIG_NETFILTER_XT_MATCH_HL=y/CONFIG_NETFILTER_XT_MATCH_HL=n/' .config
grep CONFIG_NETFILTER_XT_TARGET_HL .config
grep CONFIG_NETFILTER_XT_MATCH_HL .config

sed -i 's/CONFIG_NETFILTER_XT_TARGET_TCPMSS=y/CONFIG_NETFILTER_XT_TARGET_TCPMSS=n/' .config
sed -i 's/CONFIG_NETFILTER_XT_MATCH_TCPMSS=y/CONFIG_NETFILTER_XT_MATCH_TCPMSS=n/' .config

grep CONFIG_NETFILTER_XT_TARGET_TCPMSS .config
grep CONFIG_NETFILTER_XT_MATCH_TCPMSS .config

scripts/config --disable CONFIG_NETFILTER_XT_TARGET_HL
scripts/config --disable CONFIG_NETFILTER_XT_MATCH_HL

grep CONFIG_NETFILTER=y .config
grep CONFIG_NETFILTER .config
grep CONFIG_IP_NF_TARGET_ECN=y .config

cat net/netfilter/Makefile | grep "xt_HL.o"
cat net/netfilter/Makefile | grep "CONFIG_NETFILTER_XT_TARGET_HL"

# In net/netfilter/Makefile, comment the lines below:
# obj-$(CONFIG_NETFILTER_XT_MATCH_HL) += xt_hl.o
# obj-$(CONFIG_NETFILTER_XT_TARGET_TCPMSS) += xt_TCPMSS.o
# obj-$(CONFIG_NETFILTER_XT_TARGET_HL) += xt_HL.o

# git log -- net/ipv4/netfilter/ipt_ECN.c

sudo apt update
sudo apt install dwarves

# sudo make clean
mkdir /tmp/make
# sudo make mrproper O=/tmp/make EXCLUDE_DOCS=1

# rm -rf build/
# rm -rf .tmp/
# rm -rf .dep/
# make dep

# make olddefconfig
sudo make -j$(nproc) CFLAGS="-I ./include -H"
sudo make modules_install -j$(nproc)
sudo make install -j$(nproc)

# BTF (BPF Type Format) est un format de débogage compact utilisé pour fournir des informations sur les types de données du noyau Linux. 
# Il est essentiel pour certaines fonctionnalités avancées de BPF (eBPF)
# pahole -C task_struct vmlinux.o
# pahole --btf_encode_det vmlinux.o

# Warning: "Clock skew detected"
# ➜ Cela signifie que l’horloge du système de fichiers n'est pas synchronisée. Si tu compiles sur un disque monté via WSL, une VM, ou un système de fichiers réseau, cela peut causer des problèmes.

# /!\ Dans WSL2 la commande hwclock n'est pas disponible, car il n'y a pas d'accès direct au matériel, notamment aux horloges système en temps réel comme dans une machine physique.

# Solution :
# sudo hwclock -w # pour synchroniser l'horloge matérielle avec le système.
# date && hwclock # Vérifie la synchronisation avec 
timedatectl

ls -al vmlinux
cp -rf vmlinux $VM_LINUX_PATH # /mnt/c/github/"$OS_VER-microsoft-standard"

```

Run PowserShell
```bash
$Env:UserName

# set the right path for C:\sources\vmlinux , ex: "C:\5.15.167.4-microsoft-standard"
@"
[WSL2]
kernel=C:\\sources\\vmlinux
"@ | Set-Content -Path "$Env:UserProfile\.wslconfig"

wsl --shutdown
wsl

usbipd list
$BUS_ID="7-2" # example in my case, take the right one for you
usbipd bind --busid $BUS_ID
usbipd attach --wsl --busid $BUS_ID
```

```bash
lsusb
lsblk
ls -al /dev/sdd*

# If omitted, the default filesystem type is "ext4".
mkdir /mnt/d
sudo mount /dev/sdd1 /mnt/d
ls -al /mnt/d

# wsl --mount \\.\PHYSICALDRIVE1 D: /mnt/d -t vfat32
# sudo umount /mnt/d; sudo mount -t drvfs D: /mnt/d -o metadata,uid=1000,gid=1000

# lsblk
lsblk
```


# Secure Wipe USB-Drive
```bash
bash ./python3 wipe.py
```

```console

```