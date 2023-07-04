# SEV-SNP on QEMU

The following instructions refer to the official
[AMDSEV](https://github.com/AMDESE/AMDSEV/tree/snp-latest) repo, branch
`snp-latest` and commit `c24c972e400732a1dd7f2601f11b9c7a925d6845`. 

The instructions below assume that the host is configured correctly and all
necessary packages have already been built according to the
[host-setup](host-setup.md) guide.

## Fix launch-qemu-sh script

The `launch-qemu.sh` script in the AMDSEV repo has some issues related to
networking and other stuff. For example, it does not setup a bridge network,
meaning that you cannot SSH into the guest.

It is recommended to copy the `launch-qemu.sh` from the
[linux-svsm](https://github.com/AMDESE/linux-svsm/tree/main) repo to the
`AMDSEV/snp-release-<date>` folder from which you will run the VM.

To set up a bridge network, then, simply pass the flag `-bridge virbr0`. This
requires the virtual interface `virbr0` to be present in the system, which
should come with the `libvirt` library.

## Prepare guest

### Create disk and install guest OS

Images created with the method described in [kvm-sev](./kvm-sev.md) might have
networking issues with QEMU. Better to use `launch-qemu.sh` as follows:

```bash
# Create empty disk
qemu-img create -f qcow2 guest.qcow2 10G

# Get Ubuntu ISO
wget -O ubuntu.iso https://releases.ubuntu.com/22.04.3/ubuntu-22.04.3-live-server-amd64.iso

# Launch QEMU with disk
sudo ./launch-qemu.sh -hda guest.qcow2 -cdrom ubuntu.iso -bridge virbr0

# NOTE: in GRUB, enable console as follows:
# Press `e` to edit commands before booting
# In the `linux` line after `/casper/vmlinuz` add `console=tty0 console=ttyS0,115200n8`
# Press CTRL-X to boot

# Proceed with the installation of ubuntu and then reboot

# Install the SNP-enabled kernel and headers as shown in the next section
```

### Copy and install SNP packages to guest

You should copy the files under `<root_folder>/snp-release-<date>/linux/guest` to
the guest. You can either use SCP or mount the folder to the guest. One of the
two `linux-image` is for debugging (has `dbg` somewhere in the file name).

```bash
# [Host] Copy guest packages to guest
## You can do this either using SCP or by mounting the folder
scp <root_folder>/snp-release-<date>/linux/guest/*.deb ubuntu@<ip>:/home/ubuntu

# [Guest] Install headers
sudo dpkg -i linux-headers*.deb

# [Guest] Install kernel
## NOTE: you probably have two kernels here, one "normal" and one for debug
##       select the one you want
sudo dpkg -i linux-image*.deb

# [Host] Copy kernel and initrd locally (used later for attestation)
scp ubuntu@<ip>:/boot/initrd.img-*-snp-guest-* .
scp ubuntu@<ip>:/boot/vmlinuz-*-snp-guest-* .

# Set up dm-crypt

# [Host] Copy modules and binaries needed for initramfs
scp ubuntu@<ip>:/lib/modules/6.6.0-rc1-snp-*/kernel/drivers/md/dm-integrity.ko .
scp ubuntu@<ip>:/usr/sbin/depmod .

# [Guest] disable multipath service (creates some problems)
sudo systemctl disable multipathd.service

# [Guest] disable partitions: comment out the appropriate line of code
# Note: disable also EFI partition, otherwise VM will fail to boot
sudo nano /etc/fstab

# [Guest] Shutdown instance
sudo shutdown now
```

### Run SEV-SNP guest

The image is now ready!

Make sure you install and run the image with the same QEMU installation.
Otherwise some network configuration will be incorrect and you will not have
networking inside the VM (not sure about this?).

```bash
./launch-qemu.sh -hda <your_qcow2_file> -sev-snp -bridge virbr0
```

**Note** if `/dev/sev-guest` is not visible, try running `sudo modprobe sev-guest`

## Linux direct boot

This enables two things:
- Running the VM by passing kernel, initrd, and command-line arguments as
  parameters to QEMU, instead of using the ones in the disk image (if any)
- Enabling measured boot, i.e., adding measurements to the OVMF binary such that
  the launch digest will contain them to include kernel etc. to the attestation
  report.

### Prepare image

You can use any VM image (e.g., `img` and `qcow2`) that contains a valid root
filesystem (Linux-based).

This can be as simple as installing a Linux distro on an empty image (see
above), or manually creating a filesystem with
[debootstrap](https://wiki.debian.org/Debootstrap) (see also this guide
[here](https://blog.nelhage.com/2013/12/lightweight-linux-kernel-development-with-kvm/#building-a-disk-image)).
In the latter case, you won't have a kernel installed, but with linux direct
boot you don't need it.

### Prepare kernel and initrd

The kernel and initrd can be obtained as described above, after installing the
SNP-enabled kernel package.

For the kernel command-line arguments, it is very important to identify the
correct root partition to boot:

```bash
# Detect which partition contains the root filesystem
### Typically it's the partition with a `ext4` filesystem with the biggest size
virt-filesystems -a <image-file>  -l
```

It is also desirable to disable graphics by adding the `console=ttyS0
earlyprintk=serial` arguments.

### Running VM

```bash
# Launch VM using our modified launch-qemu.sh
## Check carefully the root partition, otherwise the kernel will fail to boot
./launch-qemu.sh -hda <your_qcow2_file> -bridge virbr0 -sev-snp -measured -kernel <kernel_path> -initrd <initrd_path> -append "console=ttyS0 earlyprintk=serial root=<root-partition>"
```