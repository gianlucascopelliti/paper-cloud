# dm-verity

- [Official docs of dm-verity](https://wiki.archlinux.org/title/Dm-verity)
- [veritysetup manual](https://man7.org/linux/man-pages/man8/veritysetup.8.html)
- [How-to mount QCOW2 image](https://gist.github.com/shamil/62935d9b456a6f9877b5)

## Create verity device and compute hashes

This has to be done by the guest owner on their local machine

**Mounting Root FS**

```bash
# enable NBD module
sudo modprobe nbd max_part=8

# Connect the QCOW2 as network block device
sudo qemu-nbd --connect=/dev/nbd0 <QCOW2 image>

# Find The Virtual Machine Partitions
sudo fdisk /dev/nbd0 -l

# For Ubuntu, the root partition is somehow on /dev/ubuntu-vg/ubuntu-lv
# You should be able to see this using the following commands:
sudo pvs # (shows the VG)
sudo lvdisplay <your_vg> # (we are interested in the LV path)

# (not sure it's needed) mount volume read-only
sudo mount -o ro <device> <path_of_your_choice>
```

**Compute hashes**

```bash
# The hashes will be stored in the `verity` device and the root hash in roothash.txt
sudo veritysetup format <device-root-fs> verity | grep Root | cut -f2 >> roothash.txt

# Test everything works (if no errors are printed, it worked)
sudo veritysetup verify <device-root-fs> verity $(cat roothash.txt)
```

**Create mapping and mount device**

```bash
# Create mapping
sudo veritysetup open <device-root-fs> root verity $(cat roothash.txt)

# Mount volume
sudo mount -o ro /dev/mapper/root <folder>
```

**Clean up**

```bash
sudo umount <folder>
sudo veritysetup close root
sudo qemu-nbd --disconnect /dev/nbd0
sudo vgchange -a n # only if you have ubuntu-lv
sudo rmmod nbd
```

## Updating initramfs to do the verification

**Executables**

just copy executable somewhere (like to `/bin`)

- `veritysetup`
- `depmod`: to rebuild a new system.map file for locating the modules (needed for finding dm-verity)
- `lsmod` (only for debugging, not needed)

**Other files/modules**

- `dm-verity.ko`: needs to go to `/lib/modules/6.6.0-rc1-snp-<...>/kernel/drivers/md`
    - You will find the module on the same path locally.

**Kernel parameters**

- `rootflags=noload`: to mount the root FS. Otherwise it will complain that the FS is read-only and will not mount it.
    - `noload` suppresses the loading of the journal. It seems not recommended to use. Check the implications.

**Enable `dm-verity` module**

```bash
# rebuild system map
depmod -a

# load dm-verity
modprobe dm-verity

# check that dm-verity is loaded
lsmod | grep verity
```

**Mount root disk**

```bash
# create mapping
veritysetup open <device-root-fs> root verity $(cat roothash.txt)

# mount root disk as read-only
mount -o ro /dev/mapper/root <folder>
```