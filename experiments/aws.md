# AWS

## Experiment 0: Run & attest a SEV-SNP instance

### Steps to run

Quite straightforward:
1. Create an EC2 instance in eu-west-1 (Ireland)
2. Select Amazon Linux AMI
3. Select `m6a.large` instance type
4. Enable SEV-SNP (just toggle the checkbox)
5. Assign a VPC to the instance (--> created default one)
6. Assign a SSH keypair to the instance
7. Run!

### What you get

You get a VM ready to use. Seems like it's indeed running in a SEV-SNP instance.
You can SSH into the VM using its public IP address and the keypair assigned to
the VM at step 6 (user `ec2-user`).

### Attestation

Installed `snpguest`, got report. 

However, cannot verify signature,  I need the VCEK! How to retrieve it?
- VCEK can be retrieved using `snpguest fetch` and passing the report and HW type
  (genoa, milan..) as input. This can be also done on another server. 
  - *However*, the CHIP ID in the attestation report is zero! This is set by the
      platform to "hide" the chip id from reports, check ABI spec.
- Another option is to fetch them from host memory. Again, we can use `snpguest
  certificates` for this.
  - *However*, this doesn't work as well (getting error "invalid cert type").
    Probably the certificates are not stored locally. (This doesn't work on SWT
    either, but getting a different error, i.e., segmentation fault).

Solution: the `snpguest` doesn't support VLEK! That's why I was getting errors
with `snpguest certificates`.

Indeed, the certificates are there correctly. But instead of the VCEK, there is
the VLEK. `snpguest` (particularly, the `sev` crate), doesn't support this type
of certificate (check
[here](https://github.com/virtee/sev/blob/340f65d78183fe418568848c37e5d68eb9b40dda/src/firmware/host/types/snp.rs#L34C7-L34C7)).
But by "forcing" `snpguest` to store it instead of raising an error, and then
using that in place of the VCEK, I can correctly verify the attestation report!

Also, I was able to verify the measurement!! The instance is using the latest
[release](https://github.com/aws/uefi/releases/tag/20230516) of AWS' OVMF, so it
was sufficient to run the following command to get the measurement:

```bash
# sev-snp-measure comes from commit 40e6720a2fac6dfc2336815e4c85789c487cc5b2
sev-snp-measure --mode snp --vcpus=2 --vmm-type=ec2 --ovmf=ovmf_img.fd
```