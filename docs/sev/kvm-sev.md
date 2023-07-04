# Run SEV on KVM

Note: this document only provides instructions to run (SEV-enabled) VMs on KVM
and some useful commands. SEV-ES and SEV-SNP are not used here. See
[sev-qemu](./sev-qemu.md) for more info on that.
## Useful links

- [Create Ubuntu VM and configure cloud-init](https://docs.openstack.org/image-guide/ubuntu-image.html)
- [virt-install manual](https://github.com/virt-manager/virt-manager/blob/main/man/virt-install.rst)
- [Ubuntu cloud images](http://cloud-images.ubuntu.com/)
    - [Ubuntu 22.04](http://cloud-images.ubuntu.com/jammy/current/)

### AMD SEV

- [Virtio guide](https://libvirt.org/kbase/launch_security_sev.html)
- [OVH Cloud guide](https://help.ovhcloud.com/csm/en-dedicated-servers-amd-sme-sev?id=kb_article_view&sysparm_article=KB0044018)
- [SUSE guide](https://documentation.suse.com/sles/15-SP1/html/SLES-amd-sev/index.html)

## KVM

### Manage images

```bash
# convert from QCOW2 to raw .img
qemu-img convert -f qcow2 -O raw image.qcow2 image.img

# convert from raw to QCOW2
qemu-img convert -f raw -O qcow2 image.img image.qcow2
```

### Create a VM image from ISO

```bash
# get ISO
wget -O ubuntu.iso https://releases.ubuntu.com/22.04.3/ubuntu-22.04.3-live-server-amd64.iso

# Copy iso and change ownership
cp ubuntu.iso /var/lib/libvirt/boot/
chown libvirt-qemu:kvm /var/lib/libvirt/boot/ubuntu.iso

# Create image
qemu-img create -f qcow2 /var/lib/libvirt/images/ubuntu.qcow2 10G
chown libvirt-qemu:kvm /var/lib/libvirt/images/ubuntu.qcow2

# Run image
## we need to specify "kernel" and "initrd" with the "location" flag, otherwise kvm cannot find them
## we need to specify extra args because we install over a terminal and not a GUI
## we need to specify UEFI boot in order to use AMD SEV later
virt-install \
            --virt-type kvm \
            --name ubuntu \
            --vcpus 2 \
            --ram 2048 \
            --boot uefi \
            --location=/var/lib/libvirt/boot/ubuntu.iso,,kernel=casper/vmlinuz,initrd=casper/initrd \
            --disk /var/lib/libvirt/images/ubuntu.qcow2,bus=virtio,size=10,format=qcow2 \
            --network network=default \
            --graphics none \
            --extra-args='console=ttyS0,115200n8 --- console=ttyS0,115200n8' \
            --os-variant=ubuntu22.04

# Install ubuntu...
## after installation and reboot, you should be able to use the VM
## even via SSH
```

### Export/ Import image

```bash
# Export image -> just copy disk somewhere else
sudo cp /var/lib/libvirt/images/ubuntu.qcow2 /var/lib/libvirt/images/ubuntu-copy.qcow2

# (optional) dump XML configuration
virsh dumpxml ubuntu > ubuntu.xml
```

### Import option 1: import XML configuration

```bash
# Update ubuntu.xml setting a new name, removing UUID (because already used by the original VM) 
# and changing disk path to ubuntu-copy.qcow2 (search for `qcow2`)
nano ubuntu.xml

# create new domain
virsh define --file ubuntu.xml

# Start VM
sudo virsh start ubuntu-copy
```

### Import option 2: launch new VM from image file

```bash
# We install the new VM and set the `--import` flag to skip OS installation (since it's already installed)
virt-install \
            --virt-type kvm \
            --import \
            --name ubuntu-copy \
            --vcpus 2 \
            --ram 2048 \
            --boot uefi \
            --disk /var/lib/libvirt/images/ubuntu-copy.qcow2,bus=virtio,size=10,format=qcow2 \
            --network network=default \
            --graphics none \
            --os-variant=ubuntu22.04
```

### Run VM and load image file from a remote location

```bash
sudo virt-install \
            --name ubuntu-guest \
            --os-variant ubuntu20.04 \
            --vcpus 2 \
            --memory 2048 \
            --boot uefi \
            --location http://ftp.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/ \
            --network bridge=virbr0,model=virtio \
            --graphics none \
            --extra-args='console=ttyS0,115200n8 serial'
```

## KVM and AMD SEV

### Run a secure VM using SEV

```bash
# Important to set "--cpu host" here, because otherwise we get errors
# Check other options from the links above
sudo virt-install \
              --name ubuntu-sev \
              --cpu host \
              --memory 4096 \
              --memtune hard_limit=4563402 \
              --boot uefi \
              --disk /var/lib/libvirt/images/ubuntu-sev.qcow2,bus=virtio,size=10,format=qcow2 \
              --os-variant ubuntu22.04 \
              --import \
              --controller type=scsi,model=virtio-scsi,driver.iommu=on \
              --controller type=virtio-serial,driver.iommu=on \
              --network network=default,model=virtio,driver.iommu=on \
              --memballoon driver.iommu=on \
              --graphics none \
              --launchSecurity sev
```

### RUN secure VM from a precofigured cloud image

[Tested VM: Ubuntu 22.04 Jammy](http://cloud-images.ubuntu.com/jammy/current/)

```bash
# Define a configuration file for `cloud-init`
cat >cloud-config <<EOF
#cloud-config

password: test
chpasswd: { expire: False }
ssh_pwauth: False
EOF

# Create ISO for cloud-init using the configuration file above
sudo cloud-localds /var/lib/libvirt/images/jammy-config.iso cloud-config

# Launch VM passing the iso above as "cdrom" disk to trigger cloud init
sudo virt-install \
              --name jammy-sev \
              --cpu host \
              --memory 4096 \
              --memtune hard_limit=4563402 \
              --boot uefi \
              --disk images/jammy-server-cloudimg-amd64.img,bus=virtio,size=10,format=qcow2 \
              --disk images/sevsnp_copy.qcow2,bus=virtio,size=10,format=qcow2 \
              --disk cloud-config.iso,device=cdrom \
              --os-variant ubuntu22.04 \
              --import \
              --controller type=scsi,model=virtio-scsi,driver.iommu=on \
              --controller type=virtio-serial,driver.iommu=on \
              --network network=default,model=virtio,driver.iommu=on \
              --memballoon driver.iommu=on \
              --graphics none \
              --launchSecurity sev
```

### Useful commands

```bash
# list all VMs
sudo virsh list --all

# shutdown a VM
virsh shutdown <vm>

# force shutdown
virsh destroy <vm>

# delete VM
virsh undefine <vm>

# delete VM (if it complains about nvram)
virsh undefine --nvram <vm>

# reboot a VM
virsh reboot <vm>

# start a VM
virsh start <vm>

# get info
virsh dominfo <vm>

# Open console in VM
virsh console <vm>

# Dump XML
virsh dumpxml <vm> > file.xml
```