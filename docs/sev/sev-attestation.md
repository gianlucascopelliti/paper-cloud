# SEV-SNP attestation

[Examples](https://github.com/AMDESE/sev-guest)

API: [sev](https://github.com/virtee/sev)

SVSM: [linux-svsm](https://github.com/AMDESE/linux-svsm/tree/main)

## Attestation details

### Attestation report fields

[Here](https://github.com/virtee/sev/blob/main/src/firmware/guest/types/snp.rs)
    - 672 bytes of data
    - 512 bytes of signature
    - tot: 1184 bytes

### Boot process

1. Pages are created (unvalidated) and assigned to the guest
2. Guest boots up -- UEFI bootloader
    - I assume that there is an initial configuration of the pages
    - Kernel and initrd are loaded into memory?

## Preliminaries

### [Host/Guest/GuestOwner] CLI utilities

Install CLI utilities with Cargo:
- [snphost](https://github.com/virtee/snphost), needed by host owner
- [snpguest](https://github.com/virtee/snpguest), needed by guest VM and guest owner

```bash
# Install Rust if not installed
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install common dependencies
sudo apt install -y perl gcc make libssl-dev pkg-config

# Install packages
cargo install --path ./snphost
```

### [Host] access to /dev/sev

You can access `/dev/sev` as root. But if you want to access it with your user,
you can create a group and add your user to that group:

```bash
# Create `sev` group
sudo groupadd sev

# Assign /dev/sev to `sev` group
sudo chgrp sev /dev/sev

# Set permissions to /dev/sev
sudo chmod 660 /dev/sev

# Add user to group
sudo usermod -aG sev $USER

# Reload shell..

# Ensure all checks pass
snphost ok
```

Note that this might be reset after reboot.

### [Host] Get and verify certificates

[More info](https://github.com/virtee/snphost/blob/main/docs/snphost.1.adoc)

```bash
# Get AMD certificates ARK and ASK
snphost fetch ca pem .

# Get chip's VCEK
snphost fetch vcek pem .

# Verify certificate chain
snphost verify ark.pem ask.pem vcek.pem
# • = self signed, ⬑ = signs, •̷ = invalid self sign, ⬑̸ = invalid signs
# ARK •
# ARK ⬑ ASK
# ASK ⬑ VCEK

# Import certificates to PSP
# TODO what is the purpose of this?
snphost import .

# Get CRL
snphost fetch crl .
```

### [Host] Upgrade SEV firmware

SEV-SNP requires firmware version >= 1.51:1. To update your firmware, [check
this
guide](https://github.com/AMDESE/AMDSEV/tree/snp-latest#upgrade-sev-firmware)

```bash
# check current fw version
snphost show version
```

## Attesting Guest VMs

### [GuestOwner] Compute launch digest and ID block

[Python library](https://github.com/virtee/sev-snp-measure)

```bash
# clone the repo 
git clone https://github.com/virtee/sev-snp-measure

# install the package (in a python environment)
pip install sev-snp-measure/

# Compute measurement of only OVMF bootloader
sev-snp-measure --mode snp --vcpus=4 --vcpu-type=EPYC-v4 --ovmf=<ovmf_path>

# Compute measurement including kernel, initrd and kernel arguments
sev-snp-measure --mode snp --vcpus=4 --vcpu-type=EPYC-v4 --ovmf=<ovmf_path> --kernel=<kernel_path> --initrd=<initrd_path> --append=<kernel_args>
```

### [Guest] Get and verify attestation report

[More info](https://github.com/virtee/snpguest/blob/main/docs/snpguest.1.adoc)

```bash
# Get attestation report and store in `report`, using random data as the 64-bytes Report Data field
sudo `which snpguest` report report.bin random.txt -r

# Check contents of attestation report stored in report.bin
snpguest display report report.bin

# Verify attestation report, using certificates in `certs` and report in report.bin
## Note: this only verifies the signature and TCB
snpguest verify attestation certs report.bin
```

### [GuestOwner] Verify attestation report received from guest VM

Useful links (not needed for the commands below):
- [Download page](https://www.amd.com/en/developer/sev.html)
- [Genoa ARK/ASK certs](https://download.amd.com/developer/eula/sev/ask_ark_genoa.cert)
- [VCEK/KDS specification](https://www.amd.com/content/dam/amd/en/documents/epyc-technical-docs/specifications/57230.pdf)

```bash
# Get ARK and ASK certificates for the Genoa processor
snpguest fetch ca pem Genoa .

# Get VCEK associated to the Genoa processor and attestation report `report.bin`
## Note: the attestation report contains TCB version info. So we can obtain the correct
##       VCEK based on that info
snpguest fetch vcek pem Genoa . report.bin

# Inspect VCEK certificate (optional)
openssl x509 -in vcek.pem -text -noout

# Verify certificates
snpguest guest verify certs
# The AMD ARK was self-signed!
# The AMD ASK was signed by the AMD ARK!
# The VCEK was signed by the AMD ASK!

# Verify attestation report passing the certificates path and the report
## Note: this only verifies the certificate chain and the TCB info
snpguest verify attestation . report.bin
```

## Launching a SNP VM with ID Block

The ID block can be computed using the `snp-create-id-block` tool included with
`sev-snp-measure`. Then, it can be passed to QEMU along with the ID
authentication information structure. More info is provided in the [ABI
Spec](https://www.amd.com/system/files/TechDocs/56860.pdf).

### Create ID Block

```bash
# First, we need an ID private key and an author private key
### [FIX] Due to some issues with `snp-create-id-block`, these keys *must* use
###       the P-384 elliptic curve, otherwise it would not work (wrong pubkeys)
openssl ecparam -name secp384r1 -genkey -noout -out idkey.pem
openssl ecparam -name secp384r1 -genkey -noout -out authorkey.pem

# Then, we need the expected measurement of the VM. This can be computed using
# sev-snp-measure as described above. NOTE: IT MUST BE IN BASE64 FORMAT!
sev-snp-measure --output-format base64 .... > measurement.txt

# Finally, let's compute the ID block
snp-create-id-block --idkey idkey.pem --authorkey authorkey.pem --measurement `cat measurement.txt`
```

The ID Block will have two parts:
- The first line are the parameters need to be passed to QEMU to the
  `sev-snp-guest` object, and looks like this:
  `id-block=<base64-stuff>,id-auth=<base64-stuff>`
- The second and third like are the hashes of the id and author public keys, to
  be used as a reference when verifying the attestation report (since they will
  be included).

### Run SNP VM with ID block using QEMU

The `launch-qemu.sh` file must be modified to include the ID and authentication
blocks to the `sev-snp-guest` object when launching QEMU. In the end, the QEMU
command should look like this:

```bash
./usr/local/bin/qemu-system-x86_64 \
    ...
    -object sev-snp-guest,id=sev0,...,id-block=<ID_BLOCK>,id-auth=<ID_AUTH> \
    ...
```

If the measurement matches the reference in the ID block and the signatures are
correct, the VM boots correctly. Otherwise, you may get some errors like `Bad
measurement` or `Bad signature`.

### Attesting the VM

The attestation report will include the hashes of the public ID key and author
key, which can be used by the verify to ensure they match the keys used to
generate the ID block. This guarantees that the VM was booted using an authentic
ID block, and that the measurement and policies were checked at boot time.

```bash
# Check if the hashes of the public keys in the report match the expected values
### The expected values are printed in base64 format, so we should convert them to hex
echo <key-hash-base64> | base64 -d | hd
```