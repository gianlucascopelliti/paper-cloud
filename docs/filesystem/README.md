# Filesystem Protection

## Useful commands

```bash
# Get info about a device
sudo fdisk <device> -l
```

## Ubuntu LVM

Using this kind of filesystem (LVM group) did not work for dm-verity and
dm-crypt in initramfs. Both commands hang at the following: `Udev cookie
0xd4d55ee (semid 1) waiting for zero`.

Just use a regular disk without stupid stuff.

TODO: fix this because the filesystem cannot be read.

```bash
# Create new disk
qemu-img create -f qcow2 test.qcow2 10G

# Mount disk
sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 test.qcow2 

# Create filesystem
sudo mkfs.ext4 /dev/nbd0

# Mount device
sudo mount /dev/nbd0 <folder>

# Add you stuff..

# Disconnect disk
sudo qemu-nbd --disconnect /dev/nbd0
sudo rmmod nbd
```

## Initramfs

**Unpack initrd**

```bash
unmkinitramfs initrd.img <folder>
```

**Repack initrd**

Now, there might be multiple sectors (?) that are unpacked. For example, sectors
containing AMD/Intel microcode. For example, the unpacked initramfs might look
like this:

```
<folder>
    \__early
    \__early2
    \__main
```

We need to pack them separately, e.g., like in the following script:

```bash
INITRD=$1
OUT=../../initrd.img

cd $INITRD

# Add the first microcode firmware
# --------------------------------

cd early
find . -print0 | cpio --null --create --format=newc > $OUT

# Add the second microcode firmware
# ---------------------------------

cd ../early2
find . -print0 | cpio --null --create --format=newc >> $OUT

# Add the ram fs file system
# --------------------------

cd ../main
find . | cpio --create --format=newc >> $OUT
```

## Ukify

Tool to create UKI (puts together kernel, initrd and cmd line arguments)

```bash
# Get ukify
wget --output-document=/usr/local/bin/ukify https://raw.githubusercontent.com/systemd/systemd/main/src/ukify/ukify.py && chmod +x /usr/local/bin/ukify

# create UKI
ukify build --linux <kernel-img> --initrd <initrd-img> --cmdline <cmdline>
```