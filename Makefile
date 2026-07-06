ARCH		?= arm64
BIOS		?= 1

CC	:= aarch64-none-elf-

UBOOT_SRC	?= $(GDIR)/u-boot
ATF_SRC		?= $(GDIR)/arm-trusted-firmware
ATF_OUT		?= $(ATF_SRC)/build/qemu/debug
KIMAGE		?= $(KBUILD_OUTPUT)/arch/arm64/boot/Image

OPENSSL_PREFIX	:= $(shell brew --prefix openssl 2>/dev/null)
UBOOT_HOST_FLAGS := $(if $(OPENSSL_PREFIX),HOSTCFLAGS="-I$(OPENSSL_PREFIX)/include" HOSTLDFLAGS="-L$(OPENSSL_PREFIX)/lib")

QEMU_ARGS	+= -fsdev local,security_model=passthrough,id=fsdev0,path=share
QEMU_ARGS	+= -device virtio-9p-pci,fsdev=fsdev0,mount_tag=hostshare
QEMU_ARGS	+= -nographic
QEMU_ARGS	+= -m size=1024M
QEMU_ARGS	+= -cpu max,sve=off
QEMU_ARGS	+= -smp 4
QEMU_ARGS	+= -machine virt,mte=on

ifneq ($(TCP),)
QEMU_ARGS	+= -serial tcp:127.0.0.1:2222,server,nowait
endif

ifneq ($(GDB),)
QEMU_ARGS	+= -S -s
RUN_QEMU_BAK	:= gnome-terminal --
RUN_GDB		:= run_gdb
GDB_ARGS	:= -q --ex 'target remote :1234'
endif

ifneq ($(BIOS), 0)
BIOS_BIN	:= bios.bin
ATF_ARGS	:= PLAT=qemu DEBUG=1 ENABLE_FEAT_MTE2=1 BL2_AT_EL3=1 BL33=$(UBOOT_SRC)/u-boot.bin
QEMU_ARGS       += -bios $(BIOS_BIN)
QEMU_ARGS       += -machine secure=on
GDB_ARGS	+= --ex 'add-symbol-file $(ATF_OUT)/bl31/bl31.elf'
endif

ifneq ($(DTB), 0)
QEMU_ARGS	+= -dtb qemu.dtb
endif

# kernel boot args
KERNEL_ARGS	+= rdinit=/linuxrc nokaslr
#KERNEL_ARGS	+= trace_event="regulator_set_voltage"

ifeq ($(ARCH), arm64)
KBUILD_OUTPUT	?= $(GDIR)/out/gki/
ROOTFS		?= rootfs.cpio.gz
ROOTFS_DIR	?= rootfs

QEMU_ARGS	+= -machine gic-version=3
QEMU_ARGS	+= -machine iommu=smmuv3
KERNEL_ARGS	+= console=ttyAMA0
endif

ifeq ($(ARCH), riscv)
KBUILD_OUTPUT	?= $(GDIR)/out/riscv
ROOTFS		?= $(GDIR)/busybox/rootfs-riscv.cpio
endif

ifeq ($(QEMU_LOG), 1)
QEMU_ARGS	+= -d cpu -D debug.log
endif

.PHONY: rootfs run

run: rootfs run_qemu

run_qemu: $(BIOS_BIN) $(ROOTFS)
	$(RUN_QEMU_BAK) qemu-system-aarch64 $(QEMU_ARGS) \
	-initrd $(ROOTFS) \
	-kernel $(KIMAGE) \
	-append "$(KERNEL_ARGS)"

$(BIOS_BIN): $(ATF_OUT)/fip.bin $(ATF_OUT)/bl1.bin
	dd if=$(ATF_OUT)/bl1.bin of=$@ bs=4096 conv=notrunc
	dd if=$(ATF_OUT)/fip.bin of=$@ seek=64 bs=4096 conv=notrunc

$(ATF_OUT)/%.bin: $(UBOOT_SRC)/u-boot.bin $(ATF_SRC)
	$(MAKE) CROSS_COMPILE=$(CC) OPENSSL_DIR=$(OPENSSL_PREFIX) $(ATF_ARGS) all fip -j16 -C $(ATF_SRC)

$(UBOOT_SRC)/%.bin: $(UBOOT_SRC)
	$(MAKE) qemu_arm64_defconfig -C $(UBOOT_SRC)
	$(MAKE) CROSS_COMPILE=$(CC) $(UBOOT_HOST_FLAGS) -j16 -C $(UBOOT_SRC)

riscv:
	qemu-system-riscv64 $(QEMU_ARGS) \
	-initrd $(ROOTFS) \
	-kernel $(KBUILD_OUTPUT)/arch/riscv/boot/Image \
	-append "$(KERNEL_ARGS)"

rootfs:
	cd $(ROOTFS_DIR) && find . | cpio -o -H newc | gzip -9 > $(abspath $(ROOTFS))

dtb: dts/qemu.dts
	cpp -nostdinc -undef -I./dts -D__DTS__ -x assembler-with-cpp -o qemu.dts.tmp $<
	dtc -I dts -O dtb -o qemu.dtb qemu.dts.tmp
	rm qemu.dts.tmp

dump_dts:
	qemu-system-aarch64 $(QEMU_ARGS) -machine dumpdtb=dump.dtb
	dtc -I dtb -O dts -o dump.dts dump.dtb
	rm dump.dtb

run_gdb:
	gdb-multiarch $(GDB_ARGS) $(KBUILD_OUTPUT)/vmlinux
clean:
	rm -rf rootfs/*.ko
	rm -f rootfs.cpio.gz
