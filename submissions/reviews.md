SysTEX 2024 Paper #21 Reviews and Comments
===========================================================================
Paper #21 Understanding Trust Relationships in Cloud-Based Confidential
Computing


Review #21A
===========================================================================

Overall merit
-------------
4. Accept

Reviewer expertise
------------------
3. Knowledgeable

Paper summary
-------------
The paper analyzes gaps in the remote attestation offerings of confidential VMs of public cloud providers. Since many different components of CVMs are usually provided by the CSP, it is important that the VM owner can trust these components. To that end, these components need to be 1) analyzable by the VM owner and 2) included in the remote attestation feature of the CVM. The authors propose a hierarchy of attestation levels to compare to what extend the various TCB components of a CVM can be remotely attested by the VM owner. The authors identified that not all CSP offering CVMs enable VM owners to attest all TCB components of CVM. In this case, the VM owner has to trust the CSP provided components and therefor ultimately the CSP itself. Hence the authors argue that the goal to “remove the CSP from the TCB” is not reached yet.

Strengths
---------
The paper provides a metric to determine to what extend the TCB components of a CVM can be remote attested. 
The paper highlights the insufficiencies in the current commercial CVM offerings and discusses techniques to close remaining gaps.

Weaknesses
----------
Besides the "classical" CVM deployment approach where the CSP provides the FW & Kernel, AMD-SNP also allows for a different deployment strategy: The VM owner could deploy the CVM on a local host in a trusted environment and then initiate a CVM migration to the CSPs host. Migration will include a measurement of the migrated CVM configuration and memory content. In this scenario, all TCB components (except for the TEE itself) are provide by the CVM owner and thus inherently trusted. This approach has other organizational challenges, but it would be good to include it in the discussion. 

In Section 2.1 it says "As measuring the complete VM along with the launch of the TEE is impractical". This claim is not sufficiently elaborated in the paper.

It would have been good to get a statement from the CSP on their plans to close the attestation gaps.

Comments for authors
--------------------
Thanks for the interesting read. It is indeed important to highlight the attestation gaps of current CVM's offerings. CVM is an emerging topic and this paper helps to "nudge" the industry in the right direction.

Writing quality
---------------
3. Adequate



Review #21B
===========================================================================

Overall merit
-------------
4. Accept

Reviewer expertise
------------------
3. Knowledgeable

Paper summary
-------------
Confidential computing has shifted from user-level enclaves to confidential VMs. 
This brings new challenges and larger TCB that need to be attested. 

The concept of attestation levels presented in the paper systematizes this problem well. 
The AMD SEV-SNP analysis shows that CSPs vary in their support for attestation and this needs to be resolved to achieve truly confidential cloud computing.

Strengths
---------
- Brings attention to the attestation and trust challenges for confidential VMs
- attestation levels mapped to AMD SEV-SNP support on AWS, Azure, and Google Cloud

Weaknesses
----------
- Covers a lot of basic ground that might be redundant for SysTEX audience
- a limited and early snapshot of AMD SEV-SNP, support might improve and be better in the future for both AMD SEV-SNP and Intel TDX

Comments for authors
--------------------
The paper provides much-needed clarity about the confidential computing trust relationship. It will be a good reference that academics can use when explaining the risks of confidential computing for deployments. Since the CVMs are in their infancy, the paper can be misleading if the situation improves in the next year; I appreciate that you make this very clear in the paper that it is a snapshot of the situation as of a specific date. To look on the upside, it will serve as a good motivation for the CSPs to address these issues and prioritize them. 

Looking at the confidential computing landscape, the stakeholders you cover (manufacturers, CSPs, tenants) are integral.
However, other stakeholders have surfaced to address lift-and-shift:
- Did you look at services offered by confidential computing companies (Anjuna, Decentriq, Edgeless, Fortanix to name a few), that offer to bridge the attestation gap between the cloud interfaces and end-user needs (e.g., containers, VMs)?
- Do initiatives such as Project Amber by Intel and Project Veraison help improve attestation levels?

Writing quality
---------------
3. Adequate



Review #21C
===========================================================================

Overall merit
-------------
4. Accept

Reviewer expertise
------------------
2. Some familiarity

Paper summary
-------------
This paper investigates the state of full-stack attestation and software stack transparency for confidential virtual machine offerings by popular CSPs. The authors present a hierarchy of attestation levels to demonstrate the trust relationships involved and conclude that some trust in the CSP is still required in all of these commercially available offerings.

Strengths
---------
- Useful and informative analysis of the state of the art in commercially available CSP confidential VM offerings
- Presents the reality of the ultimate goal of eliminating trust completely in the CSP and how this remains a work in progress
- Emphasizes the importance of software stack transparency if we are to continue to reduce the TCB and trust in the CSP

Weaknesses
----------
- Authors’ claim that confidential VMs are marketed as a solution to “remove the CSP from the TCB” is overstated/false. This is definitely the end goal, but they are currently marketed as cloud confidential computing solutions where your data is confidential from the CSP, but not where you don’t trust the CSP

Comments for authors
--------------------
I appreciated and enjoyed reading this well-written survey paper which explores the gap between what confidential computing using TEEs originally intended to achieve and what the current state in CSP cloud offerings is. The authors also do a nice job in presenting concrete and useful insights into what needs to be achieved in this work in progress to get to the point where trust in the CSP is indeed reduced to a minimum. The authors acknowledge how this is still new in the market and is an evolving work in progress, which is very true. CSPs are indeed actively working to close these gaps, and having work like this get published helps shed light on how far attestability across the stack will need to go, as well as software transparency, to achieve minimum trust in the CSP. While this is ideal, a lot of technical challenges still stand in the way. In the meantime, CSPs can provide better use documentation and disclaimers on how far the attestation actually goes and what are the security guarantees and implications on trust relationships. This might also be useful to add to the conclusion, which I also appreciated especially the authors’ take on customization options.

Writing quality
---------------
4. Well-written
