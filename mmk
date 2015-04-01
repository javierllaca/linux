#!/bin/sh

trap 'exit' ERR

if [ $# -eq 2 ]; then
    NAME=$1-$2
else
    ORIG_VERSION=$(\
        cat Makefile | \
        sed -n 's/^\(VERSION\|PATCHLEVEL\|SUBLEVEL\)\ =\ \(.*\)$/\2/p' | \
        paste -sd '.')
    LOCAL_VERSION=$(\
        cat .config | \
        sed -n 's/^CONFIG_LOCALVERSION=\"-\(.*\)\"$/\1/p')
    NAME=$ORIG_VERSION-$LOCAL_VERSION
fi

# Build kernel
make -j$(($(nproc) * 2))
sudo make modules_install

sudo cp -v arch/x86/boot/bzImage /boot/vmlinuz-$NAME
sudo mkinitcpio -k $NAME -c /etc/mkinitcpio.conf -g /boot/initramfs-$NAME.img
sudo cp System.map /boot/System.map-$NAME
sudo ln -fs /boot/System.map-$NAME /boot/System.map

# Check if files exist
test -e /boot/vmlinuz-$NAME
test -e /boot/initramfs-$NAME.img
test -e /boot/System.map-$NAME
test -e /boot/System.map

# Add a boot menu
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Recompile VirtualBox guest module
sudo pacman -S virtualbox-guest-dkms || true                # never exit

VBOX_VERSION=$(\
    pacman -Q | \
    sed -n 's/^virtualbox-guest-dkms\ \([0-9]\+\(\.[0-9]\+\)*\)\(-.*\)\?$/\1/p')

sudo dkms remove  vboxguest/$VBOX_VERSION -k $NAME || true  # never exit
sudo dkms install vboxguest/$VBOX_VERSION -k $NAME

