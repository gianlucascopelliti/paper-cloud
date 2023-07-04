IMAGE ?= images/sevsnp.qcow2
ISO   ?= images/ubuntu.iso
#RUN_SCRIPT ?= linux-svsm/scripts/snp-release-2023-11-09
RUN_SCRIPT ?= AMDSEV/snp-release-2023-10-26

BUILD_PATH ?= AMDSEV

IMAGE_PATH = $(shell realpath $(IMAGE))
ISO_PATH = $(shell realpath $(ISO))

OVMF        = $(RUN_SCRIPT)/usr/local/share/qemu/OVMF.fd
KERNEL      = $(shell realpath kernel/vmlinuz-6.6.0-rc1-snp-guest-93e2466caee9)
INITRD      = $(shell realpath kernel/initrd.img-6.6.0-rc1-snp-guest-93e2466caee9)
KERNEL_ARGS = "console=ttyS0 earlyprintk=serial root=/dev/ubuntu-vg/ubuntu-lv"

SVSM_BIN    =  $(shell realpath linux-svsm/svsm.bin)

# ID Block-related stuff
USE_IDBLOCK        ?= 0
OUTPUT_DIGEST      ?= hex
IDKEY_PRIV         ?= $(shell realpath keys/idkey_private.pem)
IDKEY_PUB          ?= $(shell realpath keys/idkey_public.pem)
AUTHORKEY_PRIV     ?= $(shell realpath keys/authorkey_private.pem)
AUTHORKEY_PUB      ?= $(shell realpath keys/authorkey_public.pem)
MEASUREMENT        ?= $(shell make -s compute_digest OUTPUT_DIGEST=base64)
MEASUREMENT_KERNEL ?= $(shell make -s compute_digest_kernel OUTPUT_DIGEST=base64)

ifeq ($(USE_IDBLOCK), 1)
	IDBLOCK = $(shell make -s compute_id_block | head -n 1)
	IDBLOCK_KERNEL = $(shell make -s compute_id_block MEASUREMENT=$(MEASUREMENT_KERNEL) | head -n 1)
else
	IDBLOCK =
	IDBLOCK_KERNEL =
endif

VCPUS  = 4

compute_digest:
	sev-snp-measure --output-format $(OUTPUT_DIGEST) --mode snp --vcpus=$(VCPUS) --vcpu-type=EPYC-v4 --ovmf=$(OVMF)

compute_digest_kernel:
	sev-snp-measure --output-format $(OUTPUT_DIGEST) --mode snp --vcpus=$(VCPUS) --vcpu-type=EPYC-v4 --ovmf=$(OVMF) --kernel=$(KERNEL) --initrd=$(INITRD) --append=$(KERNEL_ARGS)

run:
	cd $(RUN_SCRIPT) && sudo ./launch-qemu.sh -hda $(IMAGE_PATH) -bridge virbr0

run_sev_snp:
	cd $(RUN_SCRIPT) && sudo ./launch-qemu.sh -hda $(IMAGE_PATH) -bridge virbr0 -sev-snp -idblock $(IDBLOCK)

run_sev_snp_svsm:
	cd $(RUN_SCRIPT) && sudo ./launch-qemu.sh -hda $(IMAGE_PATH) -bridge virbr0 -sev-snp -svsm $(SVSM_BIN)

run_sev_snp_direct_boot:
	cd $(RUN_SCRIPT) && sudo ./launch-qemu.sh -hda $(IMAGE_PATH) -bridge virbr0 -sev-snp -measured -kernel $(KERNEL) -initrd $(INITRD) -append $(KERNEL_ARGS) -idblock $(IDBLOCK_KERNEL)

setup:
	cd $(RUN_SCRIPT) && sudo ./launch-qemu.sh -hda $(IMAGE_PATH) -cdrom $(ISO_PATH)

new_disk:
	sudo rm -rf $(IMAGE_PATH)
	sudo qemu-img create -f qcow2 $(IMAGE_PATH) 20G

rebuild_all:
	cd $(BUILD_PATH) && screen -A -m -d -S sev-build -L -Logfile log.out ./build.sh --package
	sleep 0.5
	screen -r sev-build -X colon "logfile flush 0.001^M"

test_boot:
	stty intr ^n
	@echo "./$(RUN_SCRIPT)/usr/local/bin/qemu-system-x86_64 -enable-kvm -m 4096 -nographic -kernel $(KERNEL) -initrd $(INITRD) -append \"$(KERNEL_ARGS)\" -monitor pty -monitor unix:monitor,server,nowait -drive file=$(IMAGE_PATH),if=virtio" > tmpcmd
	sudo bash ./tmpcmd
	stty intr ^c
	rm tmpcmd

create_idblock_keys_ec:
	openssl ecparam -name secp384r1 -genkey -noout -out $(IDKEY_PRIV)
	openssl ec -in $(IDKEY_PRIV) -pubout -out $(IDKEY_PUB)
	openssl ecparam -name secp384r1 -genkey -noout -out $(AUTHORKEY_PRIV)
	openssl ec -in $(AUTHORKEY_PRIV) -pubout -out $(AUTHORKEY_PUB)

create_idblock_keys:
	cd keys && python generate.py

compute_id_block:
	@snp-create-id-block --idkey $(IDKEY_PRIV) --authorkey $(AUTHORKEY_PRIV) --measurement $(MEASUREMENT)