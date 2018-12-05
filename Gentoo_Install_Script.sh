# Features;
# * Booted from Gentoo minimal install CD
# * UEFI booted
# * LUKS with LVM on top filesystem
# * Boot USB drive with boot and EFI partition
# * GPG-generated key-file to unlock LUKS on USB key
# * Fully bootstrapped system
# * Switch from OpenRC to systemD as init daemon
# * GNOME 3 Desktop
# * Optimized for host CPU
# * Using custom repositories: [sakaki-tools] [mv]

# Caveats:
# Uses wired ethernet, WiFi setup (not yet) included

# Note; $GENTOO = /mnt/gentoo set via "export GENTOO=/mnt/gentoo" while not
# chroot-ed or on the installed OS

# Important Config Files;
# $GENTOO/etc/portage/make.conf
# $GENTOO/etc/portage/make.conf/repos.conf/gentoo.conf
# $GENTOO/etc/portage/make.conf/repos.conf/sakaki-tools.conf
# $GENTOO/etc/portage/make.conf/repos.conf/layman.conf
# $GENTOO/root/.bashrc
# $GENTOO/etc/locale.gen
#

# 1) Networking setup and SSH login
# Check for and if not present, set up networking conenctivity.
# Allow root login via SSH and use SSH to log into the system

# Check for network connectivity

echo "Checking for Internet connectivity and DHCP autoconfiguration...."

while true
do
      if ping -c 3 -W 5 1.1.1.1 1>/dev/null 2>&1
      then
            echo -en '\E[47;32m'"\033[1mS\033[0m"
            echo "You are connected to the internet!"

      else
            echo -en '\E[47;31m'"\033[1mZ\033[0m"
            echo "You are not connected to the internet!"
      fi
      clear
      sleep 1
done

# Logging in via SSH is not required since these scripts automate the process
# But in case you want to keep track of the build process remotely

# Allow root login via SSH, disabled by default
echo "Setting up SSH root login. . ."
sed -i 's/^#PermitRootLogin.*$/PermitRootLogin yes/' /etc/ssh/sshd_config
sleep 1

echo "Starting SSH. . ."
/etc/init.d/sshd start
sleep 1

echo "Generating new keys. . ."
for K in /etc/ssh/ssh_host_*key.pub; do ssh-keygen -l -f "${K}"; done
sleep 1

# Setup for the boot USB key

# Find the name of the USB key

for DEV in /sys/block/sd*
do
    if readlink $DEV/device | grep -q usb
    then
        DEV=`basename $DEV`
        echo "$DEV is a usb device, info:"
        udevinfo --query=all --name $DEV
        if [ -d /sys/block/${DEV}/${DEV}1 ]
        then
              echo "Has partitions " /sys/block/$DEV/$DEV[0-9]*
              echo "Reformatting this device. . ."
        else
              echo "Has no partitions, formatting it. . ."
        fi
        echo "Formatting. . ."
        do
        parted mklabel gpt $DEV
        parted mkpart primary fat32 0% 100% $DEV
        parted set 1 boot on $DEV
        parted print $DEV
        mkfs.vfat -F32 $DEV[1]*
        sleep

        echo "Mounting the drive in /tmp/efiboot"
        mkdir -v /tmp/efiboot
        mount -v -t vfat $DEV/$DEV[1]*
    fi
done

exit 0

# Create the GPG keyfile
echo "Creating the GPG keyfile. . ."
export GPG_TTY=$(tty)

dd if=/dev/urandom bs=8388607 count=1 | gpg --symmetric --cipher-algo AES256 --output /tmp/efiboot/luks-key.gpg

# After password has been entered and key file has been generated format the drive
# For this LUKS-setup.py is used if uncommented

# echo "Starting LUKS-setup.py. . ."
# python LUKS-setup.py

# Assumes target drive is /dev/sda and it is either empty or OK to be formatted
# ask for confirmation


echo "Select the drive to format: "
read drive

if [ $drive = "/dev/sda" ]
then
    echo "You have chosen /dev/sda"

    echo "Are you sure you want to format this drive? ALL DATA WILL BE LOST!"
    select YN in "YES" "NO"; do
      case $YN in
          YES ) echo "Formatting. . ."
                Format_Drive() {
                  parted mklabel gpt /dev/sda
                  parted mkpart primary 0% 100% /dev/sda
                } break;;
          NO ) echo "Cancelling. . ."
              exit;;
          * ) echo "Please type YES or NO"
      esac
      unset $YN
done

# Ask if the drive should be overwritten for extra security
echo "Do you wish to overwrite the drive? (WARNING! WILL TAKE A LONG TIME!)"
select $YN in "YES" "NO"; do
    case $YN in
        YES ) Drive_Overwrite() {
            dd if=/dev/urandom of=/dev/sda1 bs=1M status=progress && sync && echo "Erasing done. . ."

            }; break;;

        NO )  echo "Okay, aborting. . ."
              exit;;
    esac
    unset $YN
done

# Format the drive with LUKS using the GPG create keyfile
echo "Formatting the drive with LUKS using serpent-xts-plain64 cipher with whirlpool hash. Key size is 512. . ."
gpg --decrypt /tmp/efiboot/luks-key.gpg | cryptsetup --cipher serpent-xts-plain64 --key-size 512 --hash whirlpool --key-file - luksFormat /dev/sda1

echo "LUKS partition formatted!"

# Ask if a LUKS-header backup should be made.
echo "Do you want to make a backup of the LUKS-header? (If this header gets damaged the parition cannot be recovered by any means!)"
select YN in "YES" "NO"; do
    case $YN in
        YES ) echo "Making a LUKS-header backup in /tmp/efiboot/luks-header.img"
              cryptsetup luksHeaderBackup /dev/sda1 --header-backup-file /tmp/efiboot/luks-header.img; break;;
        NO )  echo "Okay, not making a header backup. . ."
              exit ;;
      esac
      unset $YN
done

# Unlock the LUKS partition with name selected by user

echo "What should the LUKS volume name be?"
read LUKSNAME

echo "Unlocking the LUKS partition with name ${LUKSNAME}. . ."

gpg --decrypt  /tmp/efiboot/luks-key.gpg | cryptsetup --key-file - luksOpen /dev/sda1 $LUKSNAME

# Creating the physical volume
echo "Creating the physical volume. . ."
pvcreate /dev/mapper/$LUKSNAME

# Ask for the volume group name and make it
echo "What should the volume group be called? (NOTE! For automated kernel generation this MUST be "vg1")"
read VOLGRP

echo "Creating volume group ${VOLGRP} on ${LUKSNAME}. . ."

vgcreate $VOLGRP /dev/mapper/$LUKSNAME

# Create 3 logical volumes; SWAP, ROOT and HOME. Ask for their size each time.
echo "Creating Logical Volumes. . ."

# Display total partition size;
pvdisplay | grep 'PV Size' > $PVSIZE
echo "The LUKS parition is ${PVSIZE}GB"

# Swap first

echo "Displaying available physical memory. . ."
grep MemTotal /proc/meminfo
sleep 5

echo "Choose SWAP partition size (recommendation; 2GB more than physical memory)"
read SWAPSIZE

echo "Okay, creating a SWAP partition with size ${SWAPSIZE}GB in volume group ${VOLGRP}. . ."
lvcreate --size $SWAPSIZE --name swap $VOLGRP

echo "Choose ROOT partition size (recommendation; at least 30GB). . ."
read ROOTSIZE

echo "Okay, creating a ROOT partition with size ${ROOTSIZE} in volume group ${VOLGRP}. . ."
lvcreate --size $ROOTSIZE --name root $VOLGRP

echo "Home parition will occupy the rest of the drive in volume group ${VOLGRP}. . ."
lvcreate --extents 100%FREE --name home $VOLGRP

# Calculate the size of the HOME partitions
export HOMESIZE=$(( $PVSIZE - $ROOTSIZE - $SWAPSIZE ))

echo "Partitions created;\nSWAP -> /dev/mapper/${VOLGRP}-swap with size ${SWAPSIZE}GB\nROOT -> /dev/mapper/${VOLGRP}-root with size ${ROOTSIZE}GB\nHOME -> /dev/mapper/${VOLGRP}-home with size ${HOMESIZE}GB"
unset PVSIZE ROOTSIZE SWAPSIZE HOMESIZE

# Change all partitions in the volume group to active
vgchange --available y

# Create filesystems on the logical volumes

# swap first
echo "Setting up SWAP parition with label 'swap'. . ."
mkswap -L "swap" /dev/mapper/$VOLGRP

echo "Setting up ROOT partition as EXT4 with label 'root'. . ."
mkfs.ext4 -L "root" /dev/mapper/$VOLGRP-root

echo "Setting up HOME parition as EXT4 (without 5% reserve) as 'home'. . ."
mkfs.ext4 -m 0 -L "home" /dev/mapper/$VOLGRP-home

# set the GENTOO variable as /mnt/gentoo and mount the Partitions

export GENTOO=/mnt/gentoo

echo "Mounting ROOT partition in /mnt/gentoo. . ."
mount -v -t ext4 /dev/mapper/$VOLGRP-root $GENTOO

# Create directories
echo "Creating home, boot and boot/efi directories. . ."
mkdir -v $GENTOO/{home,boot,boot/efi}

# Mount the home partition
echo "Mounting the home partition in /mnt/gentoo/home"
mount -v -t ext4 /dev/mapper/$VOLGRP-home $GENTOO/home

# Turn SWAP on
echo "Turning on the SWAP parition. . ."
swapon -v /dev/mapper/$VOLGRP-swap

# Unmount the USB key
echo "Unmounting the USB. . ."
umount -v /tmp/efiboot

# Change to /mnt/gentoo and download the stage3 tarball, CONTENTS and DIGESTS.asc files
echo "Changing to /mnt/gentoo. . ."
cd $GENTOO

echo "Checking to see what the most recent stage3 tarball is. . ."
export CURVER=`curl http://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64.txt | awk 'NF>=2 {print $(NF-1)}' | grep "2018"`

echo "Downloading the latest Stage3 tarball. . ."
wget -c http://distfiles.gentoo.org/releases/amd64/autobuilds/$CURVER

echo "Downloading CONTENTS and DIGESTS.asc. . ."
wget -c http://distfiles.gentoo.org/releases/amd64/autobuilds/$CURVER.CONTENTS
wget -c http://distfiles.gentoo.org/releases/amd64/autobuilds/$CURVER.DIGESTS.asc

echo "Files downloaded succesfully!"

# Import the Gentoo Release Engineering PGP-key, verify it's fingerprint
echo "Importing Gentoo Release Engineering Team PGP key (2D182910) from keyserver. . ."
gpg --keyserver pool.sks-keyservers.net --recv-key 2D182910

echo "Key retrieved, checking fingerprint. . ."
