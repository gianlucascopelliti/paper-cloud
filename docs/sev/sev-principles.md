# SEV

[SEV-SNP Whitepaper](https://www.amd.com/content/dam/amd/en/documents/epyc-business-docs/white-papers/SEV-SNP-strengthening-vm-isolation-with-integrity-protection-and-more.pdf)

Basic principles:

- SEV: memory confidentiality
- SEV-ES: confidentiality of CPU registers -- VM register state during context
  switches
- SEV-SNP: integrity protection

SEV only protects data in use. Need Full Disk Encryption (FDE) to protect disk.

- AMD Secure Processor (SP)
  - formerly known as Platform Security Processor (PSP)
  - It's a co-processor that does security stuff (SME, SEV, fTPM)
  - Root-of-trust AMD CPU and hosts the firmware for the SEV API

## Questions

- `Every vCPU is assigned a VMPL`: how does this work for a multicore scenario
  if every vCPU has a different VMPL?

## Threat Model

### Trusted

- AMD Hardware and Firmware
    - AMD Secure Processor (AMD-SP)
- SNP VM

### Untrusted

- CPU BIOS
- Device drivers
- External PCI devices (NIC, HDD, ...)
- Hypervisor
- Legacy VMs / cloud management software / other VMs

## SEV-SNP

- Each page of the guest has a "c-bit" (encrypted bit) that says whether the
  page is private (encrypted - 1) or shared (unencrypted - 0).
  - Shared pages are typically used for I/O communication
- Prevents TCB rollback attacks

### Reverse Map Table (RMP)

Provide integrity protection against replay attacks, data corruption, memory
aliasing (map two pages to the same physical page).

- Single data structure shared by all guests
- One entry for every 4k page of DRAM
- Tracks the owner for each page memory (e.g., hypervisor, VM, AMD-SP)
- Only the owner of the page can write to it (otherwise: page fault)
- RMP checks are done using the _physical_ addresses
    - For VMs, there is a double resolution from guest virtual address (GVA) to
      guest physical address (GPA) to system physical address (SPA)
        - The GPA is also stored in the RMP such that we can check if the page
          belongs to that specific VM.
- RMP checks are not done for page reads because there is already data
  confidentiality implemented
- RMP is not directly writeable in SW. There are CPU instructions that the
  hypervisor can use to assign/remove pages etc.

### Page Validation

Protects against memory re-mapping (e.g., hypervisor mapping a guest page to
multiple physical pages at runtime).

Memory mappings:
- _One SPA associated to only one GPA_: by construction, since the RMP has one
  entry per SPA page, and in each entry there is information about which GPA is
  associated to the SPA.
- _One GPA associated to only one SPA_: **no protection by construction**,
  because multiple SPA entries can be associated to the same GPA.

Example re-mapping attack:
1. Hypervisor creates a GPA for the guest, mapping it to a SPA X in the RMP
2. After some time, hypervisor adds a new mapping in the RMP for the same GPA,
   but to a SPA Y instead
3. At this point, the GPA is mapped to two different SPAs
4. The hypervisor modifies the nested page table (NPT) to re-map the GPA to SPA
   Y (the page table is not SNP-aware, the hypervisor has full control)
5. Next time the guest accesses the GPA, it reads memory from SPA Y.

Solution:
- RMP contains a Validated bit for each page, initially cleared to 0. This page
  cannot be used neither by hypervisor nor VMs, until it's validated
- The VM owner of the page can validate it by calling the `PVALIDATE` CPU
  instruction
- Two-step process:
    1. Hypervisor assigns page to guest using `RMPUPDATE` (Validated bit set to
       0)
    2. Guest validates it using `PVALIDATE`. From now on the page can be used
    3. If a re-mapping attack occurs, any GPA reads will trigger an exception
       because the validated bit of the new SPA entry in the RMP will be 0.
- To ensure that this works, guests should never validate more than once!
  Example: validate all memory at boot and never again.

### Page states

- `HYPERVISOR`: default state, used for hypervisor memory, legacy VMs and shared
  memory
- `GUEST-INVALID`: page assigned to guest but not validated yet
- `GUEST-VALID`: assigned to guest and valid
- `PRE-GUEST`: immutable, initial temporary state when launching guest
- `PRE-SWAP`: immutable, before swapping pages to disk
- `FIRMWARE`: immutable, used by AMD SP, temporary until SP has configured it
- `METADATA`: immutable, metadata for swapping guest pages to disk
    - Example: contains AES-GCM tag of swapped pages to ensure integrity of
      pages when they are swapped back into memory
- `CONTEXT`: immmutable, context pages used by SP

### Virtual Machine Privilege Levels (VMPLs)

- VMPL0: highest
- VMPL3: lowest
- Every vCPU is assigned a VMPL
- RMP entries augmented with page access rights
- By default, validated pages are assigned VMPL0. Can be changed with
  `RMPADJUST`
- VMPLs can be seen as nested virtualization. 
    - More privileged layer at VMPL0 that does some privileges instructions and
      talk with the hypervisor
    - OS running at VMPL1
- With privileged layer running at VMPL0, the OS can be completely SEV-unaware!
    - Without privileged layer, the OS needs to set C-bit in page tables,
      handle #VC exceptions, manage RMP entries, etc.
    - With privileged layer handling this stuff, the OS doesn't need to care
- virtual Top of Memory (vTOM): commodity use for encrypted/shared memory to
  simplity guest OS software
    - memory below vTOM: private and encrypted
    - memory above vTOM: shared

### Interrupt protection

We can kinda protect how interrupts are delivered to VMs and which kind of
exceptions. But of course the hypervisor can always interrupt/shutdown the VM.

### Trusted CPUID

- Hypervisor emulates CPUID instructions called by VM and may limit features
  available to guests. This of course can be also done in malicious way
- AMD-SP can verify CPUID results to ensure that the features reported by the
  hypervisor are _no greater_ than the capabilities of the platform and
  sensitive info is correct.
- CPUID filtering can be done either once at boot or on-the-fly

### Versioned keys

- Versioned Chip Endorsement Key (VCEK): private key unique to each AMD chip
  running a specific TCB version. Derived from the Chip Endorsement Key (CEK).
- Versioned Loaded Endorsement Key (VLEK) -- from firmware version 1.54: private
  key unique to each cloud vendor. Can be used as an alternative to the VCEK
  when signing attestation reports. It is requested by the cloud vendor to AMD
  and is tied to a specific TCB and chip ID. AMD then generates the VLEK based
  on secret seed, and then wraps (i.e., encrypts) in such a way that it can only
  be decrypted by that specific chip (using fused secrets).

VCEK and VLEK can be used interchangeably. The hypervisor can restrict guests to
use only the VLEK. The guest can ask the AMD SP to generate a report using one
or the other key.

### Key Hierarchy

[API Spec Chapter 2: Key Management](https://www.amd.com/content/dam/amd/en/documents/epyc-technical-docs/programmer-references/55766_SEV-KM_API_Specification.pdf)

Each of the following signs the next and is signed by the previous (or self
signed in cse of the ARK):
1. [AMD] AMD Root Key (ARK): RSA 2048. Root-of-trust of AMD. Signs the ASK.
2. [AMD] AMD Signing Key (ASK): RSA 2048. Intermediate key of AMD used to sign
   the CEK.
3. [Chip] Chip Endorsement Key (CEK): P-384 elliptic curve key. Root-of-trust of
   the AMD chip. Signs the PEK. The VCEK is derived from the CEK.
4. [Chip] Platform Endorsement Key (PEK): P-384 elliptic curve key. Signs the
   PDH. Generated from a secure entropy source.

**Other asymmetric keys:**

- Platform Diffie-Hellman Key (PDH): P-384 elliptic curve key. Use to negotiate
  master secret between AMD firmware and external entities. Generated from a
  secure entropy source. Signed by PEK.
- Owner Certificate Authority Signing Key (OCA). P-384 elliptic curve key.
  Root-of-trust of the platform owner. Signs the PEK to demonstrate ownership of
  the platform. (Does that mean that an attacker can claim ownership of a
  platform? See "Ownership" 1.2.4).

**Other symmetric keys:**

- Transport Integrity Key (TIK): HMAC-SHA256 key. Integrity protection between
  AMD firmware and external entities such as guests
- Transport Encryption Key (TEK): AES-128 encryption key. Same as above but for
  confidentiality.
- Key Encryption Key (KEK): AES-128 encryption key. Ephemeral key used to wrap
  the TIK and TEK during session establishment, destroyed after that. Derived
  from the master secret negotiated during key agreement (see PDH).
- Key Integrity Key (KIK): HMAC-SHA-256 key. Same as above but for integrity.
- VM Encryption Key (VEK): AES-128 encryption key. The UMC (??? Memory
  Controller) uses this key to encrypt guest memory at runtime. Generated from a
  secure entropy source. Lifetime of the key is the lifetime of the guest.
  Different VEK is used when VM is migrated to another platform.


### VM Launch & Attestation

- SNP VMs start from _unencrypted_ initial image (e.g., with guest VM boot code
  etc.)
    - The hypervisor asks the AMD-SP to install pages in the guest
- AMD-SP measures the content of such initial pages into a _launch digest_
    - Also with the metadata associated to these pages (GPA and type of page)
- At the end of the launch, guest owner can provide signed Identity Block (IDB)
    - Contains info to uniquely identify VM (e.g., nonce)
    - Contains expected measurement (-> boot attestation)
- Attestation reports can be obtained at any time from guest to AMD-SP
    - The AMD-SP provides a keypair to the guest, which can use them to
      communicate to the SP and e.g., request attestation reports
- Attestation report contains IDB, system info, and arbitrary data supplied by
  guest
- Reports are signed with VCEK
  - Signature differs every time due to the properties of ECDSA (*random number
    generation* at every signature. if two signatures were equal, private key
    might leak)
- Additional guest keys can be requested, e.g., for sealing

### VM Migration and Side-Channel protection

Not interested right now.

### ID Block

The [ABI Spec](https://www.amd.com/system/files/TechDocs/56860.pdf) contains
more info and specification on ID block and Authentication information
structures.

A Guest Owner can provide a data structure called ID Block when launching the
VM. This ID block contains the following things:
- Expected measurement
- Family ID, image ID and Guest SVN (not interpreted by firmware *not sure about guest SVN*)
- ID block version
- Guest Policy

Additionally, the Guest Owner must provide an ID Authentication Information
Structure that will essentially authenticate the ID block. It contains the
following:
- ID Key and Author Key algorithms
- ID Block signature
- Public ID key
- Public ID key signature
- Public Author Key

ID Key and Author Key are owned by the Guest Owner. Currently, the SNP firmware
only supports the P-384 elliptic curve, therefore those keys must use the same
curve.

When launching the VM, both ID and authentication blocks must be provided by the
guest owner. Then, the SNP firmware will check that the initial state of the VM
matches the values the ID block (measurement and policy), then it checks if the
signatures are correct, both the ID block signature and the ID key signature. If
any of these checks fail the launch is aborted, otherwise it succeeds.

The hashes of the public ID and author keys are added to the attestation report
of the VM. This can be checked by the guest owner to ensure that an authentic ID
block has been used, and that the measurement and policy have been checked at
boot time correctly.