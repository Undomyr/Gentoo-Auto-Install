#!/bin/bash
# Gentoo Install Script for automated installation of Gentoo Linux
# Features;
# * Booted from Gentoo minimal install CD
# * UEFI Booted (both minimal install CD and final install)
# * LUKS encrypted drive with LVM on top
# * BOOT USB driv with boot and EFI-partitions (optional)
# * GPG-generated key-file to unlock LUKS on USB
# * Fully bootstrapped system
# * Switch from OpenRC to SystemD init system
# * GNOME 3 Desktop
# * Optimized for host CPU
# * Using custom repositories: [sakaki-tools] [mv]

# NOTE: $GENTOO = /mnt/gentoo

# INSTALL STAGE 1
# SETUP networking

# Let's get started!
# First, check for Network Connectivity

echo "Okay, let's check if you are connected to the internet..."
while true
do
        if pint -c 3 -W 5 1.1.1.1>/dev/null 2>&1
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

# Loggin in via SSH is not required since the install is automated
# In case you DO want to keep track remotely via screen we need to
# Do some configuration, allowing for root login, generating new
# SSH-keys, setting the root password and starting the SSH daemon

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

# Setup the boot USB key
for DEV in /sys/block/sd*
do
        if readlink $DEV/device | grep -q usb
        then
                DEV=`basename $DEV`
                echo "$DEV is a usb device, info: "
                udevinfo --query=all --name $DEV
                if [ -d /sys/block/${DEV}/${DEV}1 ]
                then
                        echo "Has paritions " /sys/block/$DEV/$DEV[0-9]*
                        echo "Reformatting this device. . ."
                else
                        echo "Has no partitions, formatting it. . ."
                fi
                echo "Formatting. . ."
                parted $DEV mklabel gpt mkpart primary fat32 0% 100% set 1 boot
                on print

