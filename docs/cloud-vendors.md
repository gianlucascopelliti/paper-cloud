# Cloud Vendors and AMD SEV-SNP

## Azure

### Customizable firmware

- There was a
  [preview](https://techcommunity.microsoft.com/t5/azure-confidential-computing/azure-confidential-vms-using-sev-snp-dcasv5-ecasv5-are-now/ba-p/3573747)
  on deploying a customizable firmware to Azure, but now it is discontinued and
  not supported anymore (source: Ericsson internal -- Filippo Rebecchi)

- Seems like they support disk encryption and even user encryption with
  dm-crypt. Need to investigate this.
- [Github scripts for attestation and other
  stuff](https://github.com/Azure/confidential-computing-cvm-guest-attestation/tree/main)
- [Read this article talking about disk encryption](https://thomasvanlaere.com/posts/2023/12/azure-confidential-computing-confidential-temp-disk-encryption/)
  - Seems like you either let Azure manage the keys or you create a key and
    store it in Azure servers like an HSM. You cannot get away with that...

### Ericsson Product Security - Trust modeling

- [Main Page](https://ericsson.sharepoint.com/sites/ProductSecurity/SitePages/TrustModeling.aspx)
- [SEV-SNP with MAA](https://ericsson.sharepoint.com/:u:/r/sites/ProductSecurity/SitePages/Microsoft-Azure-Attestations.aspx)

## AWS

- [Open Source Firmware!](https://github.com/aws/uefi)
- Cannot yet attest kernel, not part of OVMF. Check [this issue](https://github.com/aws/uefi/issues/13)
  - vTPM is in the hypervisor

- Public. Currently, only US East (Ohio) and Europe (Ireland) are supported.
- Raw report available and Open firmware
- vTPM is in the hypervisor (NitroTPM)
- Seems like there is some flexibility for custom images ad
  [kernels](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/UserProvidedKernels.html)..
  question is how much of that is usable. I don't think you can provide
  kernel/initrd/params separately, it's all packaged together with the image
  (AMI). In any case, none of this is currently attestable until the FW supports
  some kind of measured boot (either via vTPM or kernel hashes)
- root FS can be encrypted, the question is about key management here. Can I
  provide an encrypted root FS (that I encrypted myself with my key) to my
  SEV-SNP instance? Not sure about that.

In general the feeling is that AWS gives you lots of flexibility, but for now
this is still not enough for higher levels.

Tested via experiments:
- L1
- L2

## GCP


- Public preview since a couple of weeks ago (end Jan 2024). Only available via
  CLI or REST API.

>Today it is available in us-central1, europe-west4, and asia southeast1. We
>also plan to add >europe-west3 by GA. Due to the overall stability observed, we
>are optimistically targeting GA >towards the end of Q1'24. For GA, we hope to
>have more to add from the attestation and trust story >perspective so stay
>tuned!

- Private firmware
- Seems that vTPM is in the hypervisor
- You can [import virtual disks](https://cloud.google.com/compute/docs/import/importing-virtual-disks) but there are limitations. For linux you can't use UEFI apparently, which would prevent the disk from run on SEV-SNP. They also say that encryption is not supported (because we need a key), but would that work with a custom initial ramdisk? Not sure.
  - [Guide to create custom OS](https://cloud.google.com/compute/docs/images/building-custom-os)
  - GCP's
    [precheck](https://github.com/GoogleCloudPlatform/compute-image-import/tree/main/cli_tools/import_precheck/precheck)
    tool that runs some check on your VM to verify if it's importable or not.

Tested via experiments:
- L1