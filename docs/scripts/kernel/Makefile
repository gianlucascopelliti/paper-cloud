INITRD_SRC ?= initrd.img-6.6.0-rc1-snp-guest-93e2466caee9
INITRD_DST ?= initrd.img
INITRD_FLD ?= tmp
INIT ?= $(INITRD_FLD)/main/init
PATCH ?= patch-initrd.txt
ORIGINAL ?= old/init_original

DM_INTEGRITY_KO        = $(shell ls /lib/modules/*/kernel/drivers/md/dm-integrity.ko | tail -n 1)
INTEGRITYSETUP         = $(shell which integritysetup)
DEPMOD                 = $(shell which depmod)

compute_patch:
	diff $(ORIGINAL) $(INIT) > patch-initrd.txt || true

patch:
	patch $(INIT) $(PATCH)

copy_files:
	cp $(DM_INTEGRITY_KO) $(INITRD_FLD)/main/lib/modules/*-snp-*/kernel/drivers/md/
	cp $(INTEGRITYSETUP) $(INITRD_FLD)/main/usr/sbin
	cp $(DEPMOD) $(INITRD_FLD)/main/usr/sbin

initramfs_unpack:
	unmkinitramfs $(INITRD_SRC) $(INITRD_FLD)

initramfs_pack:
	./make.sh $(INITRD_FLD) $(shell realpath $(INITRD_DST))

initramfs: initramfs_unpack patch copy_files initramfs_pack clean

clean:
	rm -rf $(INITRD_FLD)