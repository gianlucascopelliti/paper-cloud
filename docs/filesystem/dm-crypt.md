# dm-crypt

- [Integrity protection with dm-crypt](https://archive.fosdem.org/2018/schedule/event/cryptsetup/attachments/slides/2506/export/events/attachments/cryptsetup/slides/2506/fosdem18_cryptsetup_aead.pdf)

## Prepare disk

- [nice guide](https://www.cyberciti.biz/security/howto-linux-hard-disk-encryption-with-luks-cryptsetup-command/)

**Mounting Root FS**

```bash
# enable NBD module
sudo modprobe nbd max_part=8

# Connect the QCOW2 as network block device
sudo qemu-nbd --connect=/dev/nbd0 <QCOW2 image>

# Mount FS locally
sudo mount <device> src/
```

**Create encrypted FS**

```bash
# create new empty disk
qemu-img create -f qcow2 <name> 10G

# Mount disk
sudo qemu-nbd --connect=/dev/nbd1 <name>

# format: a prompt will show up asking for confirmation and a password
sudo cryptsetup luksFormat --type luks2 /dev/nbd1 --cipher aes-xts-random --integrity hmac-sha256

# map device: a prompt will ask for the password
sudo cryptsetup luksOpen /dev/nbd1 root
```

**Prepare encrypted partition**

```bash
# Create filesystem
sudo mkfs.ext4 /dev/mapper/root

# Mount volume
sudo mount /dev/mapper/root dst/

# Copy back all files to the encrypted partition
sudo rsync -axHAWXS --numeric-ids --info=progress2 src/ dst/
```

**Clean up**

```bash
sudo umount src/
sudo umount dst/
sudo cryptsetup luksClose root
sudo qemu-nbd --disconnect /dev/nbd0
sudo qemu-nbd --disconnect /dev/nbd1
sudo rmmod nbd
```

## Updating initramfs to do the verification

**Executables**

just copy executable somewhere (like to `/bin`)

- `depmod`: to rebuild a new system.map file for locating the modules (needed for finding dm-verity)
- `lsmod` (only for debugging, not needed)

**Other files/modules**

- `dm-integrity.ko`: needs to go to `/lib/modules/6.6.0-rc1-snp-<...>/kernel/drivers/md`
    - You will find the module on the same path locally.

**Enable `dm-integrity` module**

```bash
# rebuild system map
depmod -a

# load dm-verity
modprobe dm-integrity

# check that dm-verity is loaded
lsmod | grep integrity
```

**Mount root disk**

```bash
# create mapping
cryptsetup luksOpen <device> root

# mount root disk as read-only
mount /dev/mapper/root <folder>
```

## Compatibility issues

### Before creating the encrypted VM

- `sudo systemctl disable multipathd.service`
- Disable swap: comment out swap line in `etc/fstab` (and possibly others)

### After booting the encrypted VM

- Get IP address: `sudo dhclient enp0s4 -v`