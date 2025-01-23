ARCH		:= aarch64

QEMU_ARGS	+= -fsdev local,security_model=passthrough,id=fsdev0,path=share
QEMU_ARGS	+= -device virtio-9p-pci,fsdev=fsdev0,mount_tag=hostshare
QEMU_ARGS	+= -nographic
QEMU_ARGS	+= -m size=512M
QEMU_ARGS	+= -cpu max
QEMU_ARGS	+= -smp 4
QEMU_ARGS	+= -machine virt

# kernel boot args
BOOT_ARGS	+= rdinit=/linuxrc
BOOT_ARGS	+= trace_event="regulator_set_voltage"

ifeq ($(ARCH), aarch64)
KERNEL_DIR	?= ~/gits/out/gki/
ROOTFS		?= ~/workspace/rootfs.cpio.gz

QEMU_ARGS	+= -machine gic-version=3,mte=on
BOOT_ARGS	+= console=ttyAMA0
endif

ifeq ($(ARCH), riscv)
KERNEL_DIR	?= ~/gits/out/riscv
ROOTFS		?= ~/gits/busybox/rootfs-riscv.cpio
endif

run: $(ARCH)

aarch64:
	qemu-system-aarch64 $(QEMU_ARGS) \
	-dtb qemu.dtb \
	-initrd $(ROOTFS) \
	-kernel $(KERNEL_DIR)/arch/arm64/boot/Image \
	-append "$(BOOT_ARGS)"

riscv:
	@qemu-system-riscv64 $(QEMU_ARGS) \
	-initrd $(ROOTFS) \
	-kernel $(KERNEL_DIR)/arch/riscv/boot/Image \
	-append "$(BOOT_ARGS)"

dtb: dts/qemu.dts
	cpp -nostdinc -undef -I./dts -D__DTS__ -x assembler-with-cpp -o qemu.dts.tmp $<
	dtc -I dts -O dtb -o qemu.dtb qemu.dts.tmp
	rm qemu.dts.tmp

dump_dts:
	@qemu-system-aarch64 $(QEMU_ARGS) -machine dumpdtb=dump.dtb
	dtc -I dtb -O dts -o dump.dts dump.dtb
	rm dump.dtb
