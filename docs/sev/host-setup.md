# Setup AMD SEV-SNP on the Host

## Host

### Step 1: BIOS settings

Some BIOS settings are required in order to use SEV-SNP. The settings slightly
differ, but make sure to check the following:
- `Secure Nested Paging`: to enable SNP
- `Secure Memory Encryption`: to enable SME (not required for running SNP guests)
- `SNP Memory Coverage`: needs to be enabled to reserve space for the Reverse
  Map Page Table (RMP). [Github](https://github.com/AMDESE/AMDSEV/issues/68)
- `Minimum SEV non-ES ASID`: this option configures the minimum address space ID
  used for non-ES SEV guests. By setting this value to 1 you are allocating all
  ASIDs for normal SEV guests and it would not be possible to enable SEV-ES and
  SEV-SNP. So, this value should be greater than 1.

### Step 2: Install libslirp packages for networking

AFAIS, `libslirp-dev >= 4.7` must be installed in the host _before_ building
QEMU, to support user networking. Problem is, Ubuntu 22.04 and earlier have
older versions in their default package managers. Therefore, we need to install
them manually.

Packages to install (in order):
- [libslirp0](https://packages.ubuntu.com/search?keywords=libslirp0)
- [libslirp-dev](https://packages.ubuntu.com/search?keywords=libslirp-dev)

```bash
# Get packages
wget http://se.archive.ubuntu.com/ubuntu/pool/main/libs/libslirp/libslirp0_4.7.0-1_amd64.deb -O libslirp0.deb
wget http://se.archive.ubuntu.com/ubuntu/pool/main/libs/libslirp/libslirp-dev_4.7.0-1_amd64.deb -O libslirp-dev.deb

# Install
sudo dpkg -i libslirp0.deb
sudo dpkg -i libslirp-dev.deb
```

### Step 2.9: Set up OVMF to include kernel hashes for attestation

In the AMDSEV repo (check below), OVMF doesn't include kernel hashes in the
normal build scripts. We need to change the `common.sh` as described in [this
issue](https://github.com/virtee/sev-snp-measure/issues/26):

```text
common.sh#115: replace OvmfPkg/OvmfPkgX64.dsc with OvmfPkg/AmdSev/AmdSevX64.dsc
```

Besides, we also need to patch the build process as describe in [this
issue](https://github.com/AMDESE/AMDSEV/issues/124):

```bash
cd AMDSEV/ovmf
touch OvmfPkg/AmdSev/Grub/grub.efi
```

### Step 3: Build and install SNP-enabled kernel, QEMU and OVMF

This guide refers to the `snp-latest` branch in the [AMDSEV](https://github.com/amdese/amdsev/tree/snp-latest) repo (commit `c24c972e400732a1dd7f2601f11b9c7a925d6845`).

Alternatively, I also found similar instructions in the
[linux-svsm](https://github.com/AMDESE/linux-svsm/tree/main) and
[sev-guest](https://github.com/AMDESE/sev-guest/blob/main/docs/cloud-host-setup.md)
repos.

**NOTE**: rebuilding QEMU/OVMF without updating the kernel might trigger some
errors when launching VMs. Always make sure you rebuild and reinstall everything
to get the most up-to-date versions.

```bash
# clone repo
git clone --branch snp-latest https://github.com/AMDESE/AMDSEV.git

# Build all (this will take quite some time..)
# binaries will be available in `snp-release-date`
./build.sh --package

# Copy KVM configuration file to enable SEV support
sudo cp kvm.conf /etc/modprobe.d/

# install linux kernel on host
cd snp-release-<date>
./install.sh

# Reboot machine and choose SNP host kernel from the GRUB menu
```

### Step 4: Ensure that kernel options are correct

- Make sure that IOMMU is enabled and **not** in passthrough mode, otherwise
  SEV-SNP will not work. Ensure that the iommu flag is set to `iommu=nopt` under
  `GRUB_CMDLINE_LINUX_DEFAULT`.
  [Github](https://github.com/AMDESE/AMDSEV/issues/88)
    - Check both `/etc/default/grub` and `/etc/default/grub.d/rbu-kernel.cfg`
    - If needed (i.e., if SEV-SNP doesn't work) set also `iommu.passthrough=0`

- With recent SNP-enabled kernels, KVM flags should be already set correctly.
  For earlier versions, you may need to set the following flags in
  `/etc/default/grub`:
    - `kvm_amd.sev=1`
    - `kvm_amd.sev-es=1` 
    - `kvm_amd.sev-snp=1`

- SME should not be required to run SEV-SNP guests. In any case, to enable it
  you should set the following flag: `mem_encrypt=on`.

- The changes above should be applied with `sudo update grub` and then a reboot.

### Step 5: (TEMPORARY FIX) disable debug_swap feature of KVM module

For more info, see this [Github issue](https://github.com/AMDESE/AMDSEV/issues/195#issuecomment-1808093839)

```bash
# unload KVM module
sudo rmmod kvm_amd

# reload KVM module with debug_swap feature disabled
sudo modprobe kvm_amd debug_swap=0
```


### Step 6: install KVM dependencies

Not sure this is needed when using the scripts provided in the `AMDSEV` repo,
but it's needed if you want to run VMs with KVM.

```bash
# Install KVM dependencies
sudo apt update && sudo apt install qemu-kvm libvirt-daemon-system virtinst

# Add user to `kvm` group
sudo usermod -aG kvm $USER

# logout and lo-gin

# check if the following checks pass:
##      QEMU: Checking if device /dev/kvm exist
##      QEMU: Checking if device /dev/kvm is accessible
virt-host-validate

# authorize `rw` access to /dev/sev
## add the following line right after `/dev/kvm rw,`: `/dev/sev rw,`
sudo nano /etc/apparmor.d/abstractions/libvirt-qemu
```

### Step 7: Check if everything is set up correctly on the host

Note: outputs may slightly differ.

```bash
# Check kernel version
uname -r
# 6.5.0-rc2-snp-host-ad9c0bf475ec

# Check if SEV is among the CPU flags
grep -w sev /proc/cpuinfo
# flags           : ...
# flush_l1d sme sev sev_es

# Check if SEV, SEV-ES and SEV-SNP are available in KVM
cat /sys/module/kvm_amd/parameters/sev
# Y
cat /sys/module/kvm_amd/parameters/sev_es 
# Y
cat /sys/module/kvm_amd/parameters/sev_snp 
# Y

# Check if SEV is enabled in the kernel
sudo dmesg | grep -i -e rmp -e sev
# SEV-SNP: RMP table physical address 0x0000000035600000 - 0x0000000075bfffff
# ccp 0000:23:00.1: sev enabled
# ccp 0000:23:00.1: SEV-SNP API:1.51 build:1
# SEV supported: 410 ASIDs
# SEV-ES and SEV-SNP supported: 99 ASIDs
```