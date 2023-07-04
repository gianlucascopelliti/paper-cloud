# Confidential Computing in Public Clouds

## Focus

We want to analyze on the trust model between end users, cloud providers and TEE
vendors. In particular, we focus on VM-based TEEs like AMD SEV-SNP and Intel
TDX.

Here, we consider an end user that wants to setup a confidential VM in a public
cloud (e.g., Azure). Some of the questions that we want to answer are:

1. Is the end user allowed to run a custom OS or can they only choose between a
   list of OSes provided by the cloud provider?
2. Is there any privileged software provided by the cloud provider that runs
   inside the confidential VM?
3. How is the attestation carried out? What does the user get as a response?
4. How does the user interact with the deployed VM?

Answering these questions will help understanding the trust relationships
between a customer and a cloud provider. VM-based TEEs have a large TCB, which
includes OS and other privileged software. If any of these components are
provided by the cloud provider, the trust model becomes complex. Similarly, if
the attestation protocol is performed via a service/SW provided by the cloud
provider, same problem.

Process-based TEEs are not very relevant here, because typically the end user
has complete control over what's running inside the enclave, such that
attestation can be performed by the user independently. However, two cases are
borderline here:
1. When the cloud provider offers a "confidential container"-like service (e.g.,
   via LibOSes like Gramine).
2. When the attestation is not performed by the end user, but is done via a
   service offered by the cloud vendor.

## Software TCB

In VM-Based TEE, the software TCB should _at least_ include:
- OS image
- Firmware/Bootloader (?)

"Hardware" TCB refers to trusted components that are not part of the
confidential VM but rather to the CPU (microcode, firmware, trusted components,
etc.). Here we focus on the software TCB, i.e., what exactly runs inside the
confidential VM.

## Attestation in TEEs

Attestation is particularly crucial when the end user is deploying a VM or a
service to the cloud. The user needs a strong guarantee that:
- his workload is really confidential (i.e., runs inside a TEE)
- his workload is what the user expect it to be (i.e., integrity/authenticity)

Here we are not interested in the platform measurements (platform TCB, version,
etc.), but only on what's inside the enclave.

_Binding Guest Credentials to Attestation Report_: important to establish secure
channel to VM. Basically, the attestation report includes a 64-byte field called
`REPORT_DATA`, where custom data can be added to the report by the guest
enclave/VM. The guest can, e.g., put the hash of an ephemeral public key in this
field, such that the relying party can attest that such key (and corresponding
private key) is really owned by the guest and not by some untrusted party. Also
important that this key is fresh to prevent replay attacks and similar.

### SGX

- Enclave binary contains application code (+ libOS)
- typically built locally such that the MRENCLAVE and MRSIGNER are known by the
  end user (but not always -- e.g., confidential lift-and-shift containers or
  WebAssembly binaries with runtimes such as Enarx?)
- When the binary is built locally, the user can attest the enclave
  independently. In other cases, it's a bit unclear.
- Attestation ensures integrity of the enclave at loading time (i.e., the
  binary)

### AMD SEV

- [Useful slides](https://www.amd.com/content/dam/amd/en/documents/developer/lss-snp-attestation.pdf)
- [Whitepaper](https://www.amd.com/system/files/techdocs/sev-snp-strengthening-vm-isolation-with-integrity-protection-and-more.pdf)
- [SEV Guest](https://github.com/AMDESE/sev-guest) and [SEV tool](https://github.com/AMDESE/sev-tool) tools
- [SSH key exchange example](https://github.com/AMDESE/sev-guest/blob/main/docs/ssh-key-exchange.md)

Guest includes:
- Launch metadata and measurements (owner id, guest image id, initialize image
  meaasurements, SEV-SNP guest policy, migration agents)
- Guest configuration
- x86 runtime configuration

AMD Security Processor generates attestation reports:
- guest measurements (see above)
- AMD firmware and microcode

Attestation reports are retrieved by the guest via `/dev/sev-guest`
- of course encrypted/integrity-protected to protect against hypervisor
- Then I guess that the guest sends this report itself to the verifier

A secure VM is initialized from an _unencrypted_ image containing things like
guest VM boot code.

_Virtual Machine Privilege Levels_: in SEV-SNP, the guest VM can have
hierarchical privilege levels, from VMPL0 (highest) to VMPL3 (lowest). Privilege
levels are used to set page access rights.
- This can, e.g., be used to run legacy guest VMs (unaware of SEV-SNP, so a
  privileged SW layer can run at VMPL0 acting as a "glue").

**Boot process & attestation**: kernel and initrd not included in the measurements (?)
  - SEV only (not SEV-SNP seems like)
  - [abstract & slides](https://kvmforum2021.sched.com/event/ke4h/securing-linux-vm-boot-with-amd-sev-measurement-dov-murik-hubertus-franke-ibm-research?iframe=no&w=100%&sidebar=yes&bg=no)
  - [video](https://www.youtube.com/watch?v=jzP8RlTRErk&list=PLbzoR-pLrL6q4ZzA4VRpy42Ua4-D2xHUR&index=26)
  - Maybe it's not for full VM images but happens only when you supply
    bootloader and kernel/initrd separately. In such case, only the bootloader
    is measured, while kernel and initrd are read after boot.

SEV vs SEV-ES vs SEV-SNP
- SEV: confidentiality of VM state
- SEV-ES: confidentiality of VM registers
- SEV-SNP: integrity protection (reverse map table), privilege levels,
  attestation includes memory layout (physical addrs.) and reports can be
  requested at any time

[SVSM: Secure VM Service Module](https://github.com/AMDESE/linux-svsm)
- A service running at VMPL0 that offers services to the guest OS (live
  migration, vTPM, etc.)
- [slides](https://static.sched.com/hosted_files/kvmforum2022/ca/SEV-SNP-Confidential-Guest-Services-with-SVSM.pdf)
- Not sure if the guest OS is part of the launch digest. BUT: vTPM in SVSM can
  do secure boot.

### TDX

- [td-shim](https://github.com/confidential-containers/td-shim): virtual
  firmware for TDX (TDVF)
- [edk2/OmvfPkg/IntelTdx](https://github.com/tianocore/edk2/tree/master/OvmfPkg/IntelTdx):
  TDVF reference code (?)

## Possible issues with confidential VMs

1. When the VM is launched and access is given to the user, it may already
be compromised. Example: cloud provider obtains SSH access right after instance
is started. How to protect against this? IMA? Disk integrity?
2. Attestation not done by the end user, or is done via a toolchain provided
   by the cloud vendor
3. The end user can only deploy images provided by the cloud vendor, making
   attestation impossible/useless
4. Privileged SW is running inside the confidential VM, e.g., at VMPL0.
5. The user connects to the VM via SSH and provides secrets before actually
   attesting it.
6. VM images typically are provided with the
   [cloud-init](https://github.com/canonical/cloud-init) tool, which is executed
   when the VM first boots up and used to retrieve info about the cloud vendor,
   to initialize ssh keys, create users, etc. This is crucial when used with
   confidential VMs and needs special attention.
   - user has control over vendor data
     [link](https://canonical-cloud-init.readthedocs-hosted.com/en/latest/explanation/vendordata.html)

### How to solve those issues? Is it difficult?

- All cloud vendors providing their own private firmware
  - [Nice Github discussion](https://github.com/AMDESE/linux-svsm/issues/15)

## Overview of (some of) the most popular cloud services that offer VM-based TEEs

Critical points:
- Deployment model: can the user deploy their own (unmodified) image, or how
  does that work?
- Attestation: how can the user attest the VM?
- Privileged SW & TCB: what's running inside the confidential VM apart rom the
  user image?
- Interaction: how does the user interact with the confidential VM? How can the
  user trust the connection to the confidential VM?


| Vendor                     | TEE        | Deployment Model                                  | Attestation                                 | Privileged SW & TCB             | Interaction                      |
| -------------------------- | :--------: | :-----------------------------------------------: | :-----------------------------------------: | :-----------------------------: | :------------------------------- |
| Microsoft Azure            | SEV-SNP    | [Can deploy customized images (must be loaded first separately?)](https://learn.microsoft.com/en-us/azure/confidential-computing/confidential-vm-faq-amd#can-i-customize-one-of-the-available-confidential-vm-images-)  | [Via Azure Attestation & C/C++ library provided by Azure](https://learn.microsoft.com/en-us/azure/confidential-computing/confidential-vm-faq-amd#can-i-perform-attestation-for-my-confidential-vms-). More info on [Attestation and TCB](https://github.com/Azure/confidential-computing-cvm-guest-attestation/blob/main/cvm-guest-attestation.md). Returns a JWT, embeds attestation report?! | Includes [vTPM](https://learn.microsoft.com/en-us/azure/confidential-computing/confidential-vm-overview#attestation-and-tpm), ...?                                |                                  |
| Google Cloud               | SEV-SNP    | [Can deploy customized images](https://cloud.google.com/compute/confidential-vm/docs/how-to-byoi)  | [Via vTPM](https://cloud.google.com/compute/confidential-vm/docs/monitoring). Unclear whether attestation report can be obtained | Includes [vTPM](https://cloud.google.com/compute/confidential-vm/docs/about-cvm#confidential-vm), [More info on vTPM](https://cloud.google.com/compute/shielded-vm/docs/shielded-vm#vtpm) ...?                                |                                  |
| AWS                        | SEV-SNP    | [Images supported: Amazon Linux 2023 and Ubuntu 23.04](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/snp-requirements.html). unclear whether user can deploy their images  | [Manually with AMD tooling](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/snp-attestation.html) | Not sure.                                |                                  |

## Related work

- [CoCoTPM: Trusted Platform Modules for Virtual Machines in Confidential Computing Environments](https://dl.acm.org/doi/pdf/10.1145/3564625.3564648)
- [Core slicing: closing the gap between leaky confidential VMs and bare-metal cloud](https://ab.id.au/papers/coreslicing-osdi23.pdf)
- [Towards A Secure Joint Cloud With Confidential Computing](https://ieeexplore.ieee.org/document/9898084)
- [Remote attestation of confidential VMs using ephemeral vTPMs](https://mars-research.github.io/doc/2023-acsac-svsm-vtpm.pdf)
  - [Artifacts](https://github.com/svsm-vtpm)

## Useful links

- [Confidential computing: From root of trust to actual trust - Red Hat blog](https://www.redhat.com/en/blog/confidential-computing-root-trust-actual-trust)
- [Example creation of a VM image](https://docs.openstack.org/image-guide/ubuntu-image.html)
- [Encrypted Virtual Machine Images for Confidential Computing](https://www.youtube.com/watch?v=rCsIxzM6C_I&list=PLbzoR-pLrL6q4ZzA4VRpy42Ua4-D2xHUR&index=27)
- [Remote attestation of SEV-SNP confidential VMs using e-vTPMs](https://arxiv.org/pdf/2303.16463.pdf)
- [Project Amber to replace vendor attestation services like MAA](https://www.intel.com/content/www/us/en/security/project-amber.html)
  - [Project Amber becomes Intel Trust Authority (?)](https://www.intel.com/content/www/us/en/security/trust-authority.html)
  - [Recent video explaining Amber](https://www.youtube.com/watch?v=ent75tiNSkM)
- [IETF draft: Confidential Virtual Machine Provisioning in Cloud Environment](https://datatracker.ietf.org/doc/draft-deng-teep-cvmp/)
- [Article: Toward Confidential Cloud Computing](https://dl.acm.org/doi/pdf/10.1145/3453930)
- [Master's thesis: EXPLORING APPROACHES FOR SECURE WORKLOAD DEPLOYMENT AND ATTESTATION IN VIRTUALIZATION-BASED CONFIDENTIAL COMPUTING ENVIRONMENT](https://lutpub.lut.fi/bitstream/handle/10024/164226/Artemii_Ustiukhin_LUT_Thesis_final.pdf?sequence=1)
- [IETF draft: Using Attestation in TLS](https://datatracker.ietf.org/doc/draft-fossati-tls-attestation/)
- [IETF draft: Concise Reference Integrity Manifest (CoRIM)](https://datatracker.ietf.org/doc/draft-ietf-rats-corim/)
- [in-toto Atttestation Framework](https://github.com/in-toto/attestation)
- [FOSDEM 24: Linux on a Confidential VM in a cloud: where's the challenge?](https://fosdem.org/2024/events/attachments/fosdem-2024-2394-linux-on-a-confidential-vm-in-a-cloud-where-s-the-challenge-/slides/22070/slides_fosdem2024_vkuznets_k3pOduv.pdf)

## VM-Based TEEs: Official specifications and other relevant documents

### Intel TDX

Availability: [Intel Xeon Scalable Processors 4th gen (released Q1 2023)](https://ark.intel.com/content/www/us/en/ark/products/series/228622/4th-generation-intel-xeon-scalable-processors.html)
- [preview in Azure](https://azure.microsoft.com/en-us/updates/confidential-vms-with-intel-tdx-dcesv5-ecesv5/)
- [2023-12: Public preview](https://azure.microsoft.com/en-us/updates/confidential-vms-with-intel-tdx-dcesv5-ecesv5-public-preview/)

- Spec: [Intel® 64 and IA-32 Architectures Software Developer’s Manual.](https://cdrdv2.intel.com/v1/dl/getContent/671200)

- [Report by Google on the security of TDX](https://services.google.com/fh/files/misc/intel_tdx_-_full_report_041423.pdf)

### AMD SEV-SNP

- Spec: [AMD64 Architecture Programmer’s Manual Volume 2: System Programming](https://www.amd.com/system/files/TechDocs/24593.pdf)

### ARM CCA

- [Realm Management Monitor specification](https://developer.arm.com/documentation/den0137/latest)
- [Arm Confidential Compute Architecture Software Stack Guide](https://developer.arm.com/documentation/den0127/latest)

## Notes

### In-Guest TCB

In general, it's rather difficult to understand what's exactly running inside
the guest VM amond cloud vendors. Azure provides some info in a [Github
repo]((https://github.com/Azure/confidential-computing-cvm-guest-attestation/blob/main/cvm-guest-attestation.md)),
but I could not see anything in the documentation. No info whatsoever in the GCP
documentation, though it appears obvious that there is a privileged layer below
the guest OS (for the vTPM).

In all cases where a vendor-provided component is running inside the guest VM,
attestation becomes rather useless for two reasons:
- the attestation report provided by the TEE cannot be verified (integrity
  measurements do not match / are not meaningful to the customer)
- it is not clear exactly *what* runs in the guest, and/or the SW provided by
  the cloud vendor is not open source --> no "reproducible builds".

