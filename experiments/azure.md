# Azure

## Modifying kernel of existing image

- Copy and install SEV-SNP kernel (from local)
- Check current bootloader: `efibootmgr -v`
    - take note of boot options
- Install GRUB: 
    - `sudo apt install grub-efi`
    - `sudo grub-install`
- Ensure that GRUB is used as bootloader:
    - `efibootmgr -v`: you should now see an additional boot option, which is GRUB
    - `efibootmgr --bootorder 0002`: change boot order
- Disable secure boot from Azure portal, otherwise CVM won't boot
- Reboot CVM

## Enable Linux IMA

Prerequisites:
- GRUB bootloader (for adding kernel command-line parameters -- if you don't use
  GRUB, check how to do that)
- vTPM

Procedure:
- Update kernel command-line parameters, adding `ima=on ima_policy=tcb`
    - Modify both `/etc/default/grub` and other possible files in `/etc/default/grub.d/` (don't know which exactly..)
- Run `sudo update-grub` and reboot
- Verify that command-line parameters have been updated: `cat /proc/cmdline`
- Verify that measurements are made: `cat /sys/kernel/security/ima/ascii_runtime_measurements`

## Uploading a custom image

What I did:

1. Preparing custom VHD from existing disk: [guide](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/create-upload-generic)
2. Upload VHD to Azure: [guide](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/disks-upload-vhd-to-managed-disk-cli)
3. Create CVM image: [guide](https://learn.microsoft.com/en-us/azure/confidential-computing/how-to-create-custom-image-confidential-vm)

Quite tricky to do it all correctly.

### Step 1

```bash
VM_NAME=test-20.04
RESOURCE_GROUP=sev-snp

# 
disk_name=$(az vm show --name $VM_NAME --resource-group $RESOURCE_GROUP | jq -r .storageProfile.osDisk.name)
disk_url=$(az disk grant-access --duration-in-seconds 3600 --name $disk_name --resource-group $RESOURCE_GROUP | jq -r .accessSas)

# copy
azcopy copy $disk_url <local_path>

# revoke access
az disk revoke-access -n $disk_name -g $RESOURCE_GROUP
```

### Step 2

### Step 3

We need to create a SAS to write to the container. I couldn't do it correctly
via Azure CLI (don't know why), but I used [this
guide](https://www.sqlshack.com/use-azcopy-to-upload-data-to-azure-blob-storage/
) to generate the SAS

```bash
SAS_TOKEN="copy_token_from_guide_above"

RESOURCE_GROUP=sev-snp
DISK=sevsnp-custom
STORAGE_ACCOUNT=sevsnpstorageaccount
REGION=switzerlandnorth
CONTAINER=sevsnpcontainer
GALLERY=sevsnpgallery
SIG_NAME=sevsnpcustom

# get access to disk and copy URI
DISK_URI=$(az disk grant-access --duration-in-seconds 3600 --name $DISK --resource-group $RESOURCE_GROUP | jq -r .accessSas)

# create storage account 
az storage account create --resource-group $RESOURCE_GROUP --name $STORAGE_ACCOUNT --location $REGION --sku "Standard_LRS"

# get storage account ID and store
STORAGE_ACCOUNT_ID=$(az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP | jq -r .id)

# create container
az storage container create --name $CONTAINER --account-name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP

# copy disk to container (created before)
azcopy copy "$DISK_URI" "https://$STORAGE_ACCOUNT.blob.core.windows.net/$CONTAINER/disk.vhd?$SAS_TOKEN"

# create SIG
az sig create --resource-group $RESOURCE_GROUP --gallery-name $GALLERY

# create SIG definition
az sig image-definition create --resource-group  $RESOURCE_GROUP --location $REGION --gallery-name $GALLERY --gallery-image-definition $SIG_NAME --publisher bob --offer ubuntu --sku dontknow --os-type Linux --os-state specialized --hyper-v-generation V2  --features SecurityType=ConfidentialVMSupported

# create image version
az sig image-version create --resource-group $RESOURCE_GROUP --gallery-name $GALLERY --gallery-image-definition $SIG_NAME --gallery-image-version 1.0.0 --os-vhd-storage-account $STORAGE_ACCOUNT_ID --os-vhd-uri https://$STORAGE_ACCOUNT.blob.core.windows.net/$CONTAINER/disk.vhd
```