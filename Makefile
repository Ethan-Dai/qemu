ARCH	:= aarch64

ARGS	+= -fsdev local,security_model=passthrough,id=fsdev0,path=share
ARGS	+= -device virtio-9p-pci,fsdev=fsdev0,mount_tag=hostshare
ARGS	+= -nographic
ARGS	+= -m size=512M
ARGS	+= -cpu max
ARGS	+= -smp 4
ARGS	+= -machine virt

ifeq ($(ARCH), aarch64)
ARGS += -machine gic-version=3,mte=on
KERNEL_DIR ?= ~/gits/out/gki/
ROOTFS	?= ~/workspace/rootfs.cpio.gz
endif

ifeq ($(ARCH), riscv)
KERNEL_DIR ?= ~/gits/out/riscv
ROOTFS	?= ~/gits/busybox/rootfs-riscv.cpio
endif

run: $(ARCH)

aarch64:
	qemu-system-aarch64 $(ARGS) \
	-dtb qemu.dtb \
	-initrd $(ROOTFS) \
	-kernel $(KERNEL_DIR)/arch/arm64/boot/Image \
	-append "console=ttyAMA0 rdinit=/linuxrc"

riscv:
	qemu-system-riscv64 $(ARGS) \
	-initrd $(ROOTFS) \
	-kernel $(KERNEL_DIR)/arch/riscv/boot/Image \
	-append "rdinit=/linuxrc console=ttyS0"

dtb: dts/qemu.dts
	cpp -nostdinc -undef -I./dts -D__DTS__ -x assembler-with-cpp -o qemu.dts.tmp $<
	dtc -I dts -O dtb -o qemu.dtb qemu.dts.tmp
	rm qemu.dts.tmp

dump_dts:
	@qemu-system-aarch64 $(ARGS) -machine dumpdtb=dump.dtb
	dtc -I dtb -O dts -o dump.dts dump.dtb
	rm dump.dtb
