# dm-integrity

Differences compared to dm-verity:
- dm-verity is read-only
- dm-verity works with a Merkle tree of hashes with a root, both that must be
  provided when mapping the device, and if the verification fails an error is
  raised
- dm-integrity by default provides integrity only (with CRC or SHA), but it cal
  also support HMAC-SHA256, which needs a key of course. The tags are stored in
  the device itself.
- dm-integrity can work together with dm-crypt (see dm-crypt docs), while for
  dm-verity you can still do it but you need to do dm-verity and dm-crypt
  separately (also the device will be read-only, so it will cause issues).

As said, dm-integrity can be enabled together with dm-crypt. So, dm-integrity
standalone should only be used if only integrity/authenticity is desired,
without encryption.

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

# parameters for integritysetup
INTEGRITY_PARAMS="--integrity hmac-sha256 --integrity-key-file password.txt --integrity-key-size 4"

# format: we need to store the key in a file
echo "test" > password.txt
sudo integritysetup format /dev/nbd1 $INTEGRITY_PARAMS

# map device: a prompt will ask for the password
sudo integritysetup open /dev/nbd1 root $INTEGRITY_PARAMS
```

**Prepare partition**

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
sudo integritysetup close root
sudo qemu-nbd --disconnect /dev/nbd0
sudo qemu-nbd --disconnect /dev/nbd1
sudo rmmod nbd
```