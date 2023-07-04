# Trustworthy Confidential Virtual Machines for the Masses

- Source: [arXiv](https://arxiv.org/pdf/2402.15277v1.pdf)
> "Confidential computing alleviates the concerns of distrustful customers by
> **removing the cloud provider from their trusted computing base** and resolves
> their disincentive to migrate their workloads to the cloud."

Note: need to read this paper because very relevant.

# Google Cloud Platform (GCP)

- Source: [GCP Security Products](https://cloud.google.com/security/products/confidential-computing?hl=en)
> "**Customers can be confident** that their data will stay private and encrypted
> even while being processed."

- Source: [GCP Blog on Confidential Computing](https://cloud.google.com/blog/products/identity-security/rsa-confidential-computing-transforming-cloud-security)
  - [screen](./img/google-1.png)
> "Google believes the future of computing will increasingly shift to private,
> encrypted services where users can be confident that their data is **not being
> exposed to cloud providers** or their own insiders."

# Elastys

- [Confidential Computing: Great for Security, not for Privacy](https://elastisys.com/confidential-computing/)

# Wikipedia

- Source: [Wikipedia on Confidential Computing](https://en.wikipedia.org/wiki/Confidential_computing)
  - [screen](./img/wiki.png)
> "Confidential computing protects the confidentiality and integrity of data and
> code **from the infrastructure provider**, unauthorized or malicious software
> and system administrators, and other cloud tenants, which may be a concern for
> organizations seeking control over sensitive or regulated data."

# Microsoft Azure

- Source: [Azure on Trusted Compute Base](https://learn.microsoft.com/en-us/azure/confidential-computing/trusted-compute-base)
  - [Archived version 2024-06-10](https://web.archive.org/web/20240610083112/https://learn.microsoft.com/en-us/azure/confidential-computing/trusted-compute-base)
  - [screen](./img/azure-1.png)
> "The customer workload, encapsulated inside a Trusted Execution Environment
> (TEE) includes the parts of the solution that are **fully under control and
> trusted by the customer**. The confidential computing workload is opaque to
> everything outside of the TCB using encryption."

- Source: [Azure on Lessening Trust Needs](https://learn.microsoft.com/en-us/azure/confidential-computing/overview#lessen-the-need-for-trust)
  - [screen](./img/azure-2.png)
> "Any code outside TEE can't read or tamper with data inside the TEE. The
> confidential computing threat model aims at **removing or reducing the ability
> for a cloud provider operator** or other actors in the tenant's domain accessing
> code and data while it's being executed."

- Also see [Azure Confidential Computing](https://learn.microsoft.com/en-us/industry/sovereignty/azure-confidential-computing)

Note: They have this notion of _remove or reduce_, but what does reduce mean
exactly nobody knows. Especially when Azure deploys its own proprietary
firmware, it is not a claim that really holds.

# Fortanix

- Source: [Fortanix on Virtual Private Cloud Security with Azure](https://www.fortanix.com/blog/enabling-virtual-private-cloud-security-with-azure)
  - [screen](./img/fortanix.png)
> "... puts Fortanix and Microsoft Azure in a unique position to allow Azure
> customers to adopt cloud computing while **retaining full control** of data
> security and regulatory compliance."

# Edgeless Systems

- Source: [Edgeless Systems on Confidential Computing](https://www.edgeless.systems/confidential-computing)
  - [Archived version 2024-06-10](https://web.archive.org/web/20240610082724/https://www.edgeless.systems/confidential-computing)
  - [screen 1](./img/edgeless-1.png)
  - [screen 2](./img/edgeless-2.png)
> "Confidential computing solves the trust problem of the cloud." 

> "SaaS companies inherently rely on scalable cloud offerings and need to trust
> the providers with sensitive customer data. Confidential computing ensures
> that nobody, **not even system administrators**, can access that data."


- Source: [Edgeless Systems Blog on GDPR Compliance](https://www.edgeless.systems/blog/gdpr-compliance-in-the-public-cloud-with-confidential-computing)
> "By combining confidential hardware with the right infrastructure software,
> companies can greatly reduce the trusted computing base (TCB) and **fully remove
> the cloud provider from the trust equation.**"

# Confidential Computing Consortium (CCC) Whitepaper

- Source: [CCC Outreach Whitepaper](https://confidentialcomputing.io/wp-content/uploads/sites/10/2023/03/CCC_outreach_whitepaper_updated_November_2022.pdf)
  - [screen](./img/ccc-blog.PNG)
> "Confidential Computing aims to allow the **removal of even the cloud provider
> from the Trusted Computing Base**, so that only the hardware and the protected
> application itself would be within the attack boundary."

# CCC Blog

- Source: [Introduction to Confidential Computing: A Year-Long Exploration](https://confidentialcomputing.io/2024/02/27/introduction-to-confidential-computing-a-year-long-exploration-2/)
>These secure areas of a processor ensure data is inaccessible to other
>applications, the operating system, and even cloud providers, safeguarding
>sensitive information from unauthorized access or leaks during processing.

# DBMR Nucleus Solutions

- Source: [DBMR on Confidential Computing](https://www.databridgemarketresearch.com/whitepaper/confidential-computing-the-future-of-cloud-computing-security)
  - [screen](./img/dbmr.png)
> "**Confidential Computing aims to remove the cloud provider from the Trusted
> Computing Base**, enabling workloads that were previously limited by security
> concerns or compliance requirements to be securely migrated to the public
> cloud."

# ARM European Data Protection Board

- Source: [ARM Submission to EDPB](https://www.edpb.europa.eu/sites/default/files/webform/public_consultation_reply/arm_submission_to_edpb_211220_for_recommendations_01_2020.pdf)
> "It is beneficial for the Cloud provider in this case to be able to use
> Confidential Computing technology **to remove itself and its employees** from
> possibility of coercion and therefore liability."

# ACM Special Issue on Confidential Computing

- Source: [ACM Confidential Computing Issue](https://queue.acm.org/issuedetail.cfm?issue=3623393)

- [Confidential Computing: Elevating Cloud Security and Privacy by Mark Russinovich](https://queue.acm.org/detail.cfm?id=3623461)
> "Crucially, the isolation is rooted in novel hardware primitives, effectively
> rendering even the **cloud-hosting infrastructure and its administrators
> incapable of accessing the data.**"

> "Anyone who suspects that trust has been broken by a confidential service
> should be able to audit any part of its attested code base, including all
> updates, dependencies, policies, and tools. To achieve this, we propose an
> architecture to track code provenance and to hold code providers accountable.
> At its core, a new Code Transparency Service (CTS) maintains a public,
> append-only ledger that records all code deployed for confidential services."

- [Why Should I Trust Your Code?](https://queue.acm.org/detail.cfm?id=3623460)

- [Hardware VM Isolation in the Cloud by David Kaplan](https://queue.acm.org/detail.cfm?id=3623392)
> "In confidential compute technologies such as SEV-SNP, **the cloud provider is
> untrusted**, so the only entity that can attest to the security of a VM is the
> silicon provider itself. In SEV-SNP, this service is provided by an on-chip
> entity called the ASP (AMD security processor)."

> "Confidential computing is a security model that fits well with the public
> cloud. It enables customers to rent VMs while enjoying hardware-based
> isolation that ensures that **a cloud provider cannot purposefully or
> accidentally see or corrupt their data.**"

# Confidential Containers (Microsoft's project)

- Source: [Microsoft Research on Confidential Containers](https://www.microsoft.com/en-us/research/project/confidential-containers/)
> "At present, all publicly hosted containerized compute requires including the
> Cloud Service Provider (CSP) in the TCB. This means that the operator can
> potentially compromise the functionality or data being embodied in those
> containers. **One aim of the project is to reduce the size of the TCB to contain
> only the customer containers and an open-source OS**"

- Interesting comments in the mailing list: [LKML Discussion](https://lore.kernel.org/lkml/ebae6595-1904-a12e-d964-ec3da7217b49@amd.com/T/)
> "This is inaccurate, the provider may still have software and/or hardware in
> the TCB."

> "And for the cloud use case, I very, very strongly object to implying that the
> goal of CoCo is to exclude the CSP from the TCB. Getting out of the TCB is the
> goal for _some_ CSPs, but it is not a fundamental tenant of CoCo. This
> viewpoint is heavily tainted by Intel's and AMD's current offerings, which
> effectively disallow third party code for reasons that have nothing to do with
> security."

# Alibaba Cloud

- Source: [Alibaba Cloud on Confidential Computing](https://www.alibabacloud.com/blog/a-brief-discussion-about-confidential-computing-inclavare-containers_598670)
  - [archived version 2024-06-10](https://web.archive.org/web/20240610082939/https://www.alibabacloud.com/blog/a-brief-discussion-about-confidential-computing-inclavare-containers_598670)
  - [source](./img/alibaba.png)
> "CSP is not in the tenant's Trusted Computing Base (TCB)"

# OC3 2023: CTO Panel

- Source: [OC3 2023 CTO Panel](https://www.youtube.com/watch?v=Q7Jay_db5Qo)
-  5.10 AMD CTO Mark Papermaster: 
> "You're **not** handing over to the cloud vendor control of your trusted
> confidential data. What's very paramount is the establishment of the owner of
> the data actually owning the keys. And I think that's a fundamental aspect
> customers appreciate about confidential computing."

- 11.50 Azure CTO Mark russinovich: 
> "Protecting IP of AI model ... The cloud provider shouldn't have access to
> what's being inferred on... Similarly, the cloud provider and other parties
> shouldn't have access to AI model itself ..."

- 28.20 Mark:
> "code transparency, which is critical for confidential computing,
> where you're letting somebody else's code in your confidential trust boundary,
> is that you want the ability for that code to be audited. And that means
> precisely what's that code, ... Reproducible builds.. Transparency in the
> supply chain.."
- He said that they're working on this and that can take some time.

# AMD

- Source: [Linux Security Summit 2022](https://www.amd.com/content/dam/amd/en/documents/developer/lss-snp-attestation.pdf)
  - [screen](./img/amd-threat-model-linux-summit-2022.PNG)
>Cloud Provider not trusted with confidentiality or integrity