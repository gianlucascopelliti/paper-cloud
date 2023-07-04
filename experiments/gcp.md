# GCP

## Docs

- [Create SEV-SNP instance](https://cloud.google.com/confidential-computing/confidential-vm/docs/creating-cvm-instance#gcloud)
- [Known limitations](https://cloud.google.com/confidential-computing/confidential-vm/docs/error-messages)

## Experiment 0: Run & attest a SEV-SNP instance

### Steps to run

SEV-SNP is in preview mode and only available via CLI or REST API.

List of available images:

```bash
gcloud compute images list \
    --filter="guestOsFeatures[].type:(SEV_SNP_CAPABLE)"
```

Launching a VM:

```bash
gcloud beta compute instances create gcp-00 \
  --machine-type=n2d-standard-2 \
  --min-cpu-platform="AMD Milan" \
  --zone=europe-west4-a \
  --confidential-compute-type=SEV_SNP \
  --maintenance-policy=TERMINATE \
  --image=ubuntu-2204-jammy-v20240110 \
  --image-project=ubuntu-os-cloud
```

### What you get

You get a VM ready to use. Seems like it's indeed running in a SEV-SNP instance.
You can SSH into the VM using its public IP address and a key pair that you
should configure in advance. What I did is opening a console via browser and add
my key in `authorized_keys`, then I could SSH into it (user
`gianluca_scopelliti33`).

The instance should have a permanent IP address. 

Interesting stuff: I updated the `authorized_keys` once to set my key, but
suddenly the file got restored without any reason. What is happening inside this
VM?

### Attestation

Installed `snpguest`, got report. 

However, cannot verify signature. I correctly get the VCEK (both from local
storage `snpguest certificates` and from the KDS `snpguest fetch`), but the
verification fails with the following output: 

```
Reported TCB Boot Loader from certificate matches the attestation report.
Reported TCB TEE from certificate matches the attestation report.
Reported TCB SNP from certificate matches the attestation report.
Reported TCB Microcode from certificate matches the attestation report.
thread 'main' panicked at src/verify.rs:216:21:
Invalid octet length encountered!
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
```

This should be related to the verification of the Chip ID that for some reason
fails. It seems related to the fact that the VCEK is in a different format than
what expected?

Indeed, if we comment out that part, the verification succeeds.

I also tried to print out to screen the values of the Chip ID both in the
certificate and in the report and they match. So, it is a bug in `snpguest` that
doesn't properly handle this X.509 extension type. Indeed, it triggers different
logic according to the first byte of the field, which in this case is not a
header but just the first byte of the Chip ID. I opened an issue to the repo.

Of course, it is impossible to verify the measurement as the firmware is not
open source. But we knew this already.

## Experiment 1: Validate the guest firmware

For this I used [gce-tcb-verifier](https://github.com/google/gce-tcb-verifier).

Really hard to figure out what to do and how to build the CLI tool.. In the end
I realized I needed to run the `gcetcbendorsement` tool but I couldn't figure
out how to build and run it. I ended up modifying the `testing/gcetcb/gcetcb.go`
file to point to that folder (+ `cmd`) and then build the modified `gcetcb` with
the commands below:

```bash
go build -v ./... ./gcetcbendorsement/...
go install -v ./... ./gcetcbendorsement/...
```

The executable is found at `$HOME/go/bin`. However, I couldn't get any
endorsement, got a 403 error:

```txt
# Getting endorsement from within confidential VM
# gcetcb extract --out endorsement

failed to retrieve 'https://storage.googleapis.com/gce_tcb_integrity/ovmf_x64_csm/sevsnp/c2bd4e4d7dddf90b9e5e92b762a8f576a8bef74227ec61cb9efb1a71ff4512d059f07ba94e8be56a8c24a65883a86c82.binarypb' status 403; failed to retrieve 'https://storage.googleapis.com/gce_tcb_integrity/ovmf_x64_csm/sevsnp/c2bd4e4d7dddf90b9e5e92b762a8f576a8bef74227ec61cb9efb1a71ff4512d059f07ba94e8be56a8c24a65883a86c82.binarypb' status 403; failed to retrieve 'https://storage.googleapis.com/gce_tcb_integrity/ovmf_x64_csm/sevsnp/c2bd4e4d7dddf90b9e5e92b762a8f576a8bef74227ec61cb9efb1a71ff4512d059f07ba94e8be56a8c24a65883a86c82.binarypb' status 403; failed to retrieve 'https://storage.googleapis.com/gce_tcb_integrity/ovmf_x64_csm/sevsnp/c2bd4e4d7dddf90b9e5e92b762a8f576a8bef74227ec61cb9efb1a71ff4512d059f07ba94e8be56a8c24a65883a86c82.binarypb' status 403; failed to retrieve 'https://storage.googleapis.com/gce_tcb_integrity/ovmf_x64_csm/sevsnp/c2bd4e4d7dddf90b9e5e92b762a8f576a8bef74227ec61cb9efb1a71ff4512d059f07ba94e8be56a8c24a65883a86c82.binarypb' status 403; timeout

# Getting endorsement given an attestation report
# gcetcb extract gcp.bin --out res

failed to retrieve 'https://storage.googleapis.com/gce_tcb_integrity/ovmf_x64_csm/sevsnp/c2bd4e4d7dddf90b9e5e92b762a8f576a8bef74227ec61cb9efb1a71ff4512d059f07ba94e8be56a8c24a65883a86c82.binarypb' status 403; failed to retrieve 'https://storage.googleapis.com/gce_tcb_integrity/ovmf_x64_csm/sevsnp/c2bd4e4d7dddf90b9e5e92b762a8f576a8bef74227ec61cb9efb1a71ff4512d059f07ba94e8be56a8c24a65883a86c82.binarypb' status 403; failed to retrieve 'https://storage.googleapis.com/gce_tcb_integrity/ovmf_x64_csm/sevsnp/c2bd4e4d7dddf90b9e5e92b762a8f576a8bef74227ec61cb9efb1a71ff4512d059f07ba94e8be56a8c24a65883a86c82.binarypb' status 403; failed to retrieve 'https://storage.googleapis.com/gce_tcb_integrity/ovmf_x64_csm/sevsnp/c2bd4e4d7dddf90b9e5e92b762a8f576a8bef74227ec61cb9efb1a71ff4512d059f07ba94e8be56a8c24a65883a86c82.binarypb' status 403; failed to retrieve 'https://storage.googleapis.com/gce_tcb_integrity/ovmf_x64_csm/sevsnp/c2bd4e4d7dddf90b9e5e92b762a8f576a8bef74227ec61cb9efb1a71ff4512d059f07ba94e8be56a8c24a65883a86c82.binarypb' status 403; timeout
```