#!/bin/sh

if [ $# -eq 2 ]
then
    KERN_PATH=linux-$1.tar.xz

    echo $KERN_PATH

    # Fetch source and signature
    #wget -c https://www.kernel.org/pub/linux/kernel/v3.x/$KERN_PATH

    # Extract
    #unxz $KERN_PATH
else
    echo Usage: $0 '<version> <UNI>'
fi
