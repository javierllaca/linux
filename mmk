#!/bin/sh

all_exist() {
    local flag=0
    FILES=($*)
    for file in ${FILES[*]}; do
        if [ ! -f $file ]; then
            flag=1
            echo Error: $file does not exist!
        fi
    done
    return $flag
}

if [ $# -eq 2 ]; then
    NAME=$1-$2

    # Build kernel
    make -j16 # use 8 cores
    sudo make modules_install
    sudo cp -v arch/x86/boot/bzImage /boot/vmlinuz-$NAME
    sudo mkinitcpio -k $NAME -c /etc/mkinitcpio.conf -g /boot/initramfs-$NAME.img
    sudo cp System.map /boot/System.map-$NAME
    sudo ln -fs /boot/System.map-$NAME /boot/System.map

    # Necessary files
    FILES=(/boot/vmlinuz-$NAME
           /boot/initramfs-$NAME.img
           /boot/System.map-$NAME
           /boot/System.map)

    if all_exist ${FILES[*]}; then
        # Add a boot menu
        sudo grub-mkconfig -o /boot/grub/grub.cfg

        # Recompile VirtualBox guest module
        sudo pacman -S virtualbox-guest-dkms
        sudo dkms remove  vboxguest/4.3.26 -k $NAME
        sudo dkms install vboxguest/4.3.26 -k $NAME
    fi

else
    echo Usage: $0 '<version> <UNI>'
fi
