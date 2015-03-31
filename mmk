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
    # make -j16 # use 8 cores
    make modules_install
    cp -v arch/x86/boot/bzImage /boot/vmlinuz-$NAME
    mkinitcpio -k $NAME -c /etc/mkinitcpio.conf -g /boot/initramfs-$NAME.img
    sudo cp System.map /boot/System.map-$NAME
    sudo ln -fs /boot/System.map-$NAME /boot/System.map

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
    else
        echo mmk failed
    fi

else
    echo Usage: $0 '<version> <UNI>'
fi
