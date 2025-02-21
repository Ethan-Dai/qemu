ARCH		?= arm64
QEMU_ARGS	+= -fsdev local,security_model=passthrough,id=fsdev0,path=share
QEMU_ARGS	+= -device virtio-9p-pci,fsdev=fsdev0,mount_tag=hostshare
QEMU_ARGS	+= -nographic
QEMU_ARGS	+= -m size=256M
QEMU_ARGS	+= -cpu max
QEMU_ARGS	+= -smp 4
QEMU_ARGS	+= -machine virt

ifneq ($(GDB),)
QEMU_ARGS	+= -S -s
RUN_GDB		:= run_gdb
endif

# kernel boot args
BOOT_ARGS	+= rdinit=/linuxrc
BOOT_ARGS	+= trace_event="regulator_set_voltage"

ifeq ($(ARCH), arm64)
KBUILD_OUTPUT	?= ~/gits/out/gki/
ROOTFS		?= ~/workspace/rootfs.cpio.gz

QEMU_ARGS	+= -machine gic-version=3,mte=on
BOOT_ARGS	+= console=ttyAMA0
endif

ifeq ($(ARCH), riscv)
KBUILD_OUTPUT	?= ~/gits/out/riscv
ROOTFS		?= ~/gits/busybox/rootfs-riscv.cpio
endif

UBOOT_SRC	?= ~/gits/u-boot
ATF_SRC		?= /home/ethan/gits/arm-trusted-firmware
ATF_OUT		:= $(ATF_SRC)/build/qemu/debug

run: $(RUN_GDB) $(ARCH)

arm64:
	qemu-system-aarch64 $(QEMU_ARGS) \
	-dtb qemu.dtb \
	-initrd $(ROOTFS) \
	-kernel $(KBUILD_OUTPUT)/arch/arm64/boot/Image \
	-append "$(BOOT_ARGS)"

bl.bin: $(ATF_OUT)/fip.bin $(ATF_OUT)/bl1.bin
	dd if=$(ATF_OUT)/bl1.bin of=$@ bs=4096
	dd if=$(ATF_OUT)/fip.bin of=$@ seek=64 bs=4096

$(ATF_OUT)/fip.bin $(ATF_OUT)/bl1.bin: $(UBOOT_SRC)/u-boot.bin $(ATF_SRC)
	make CROSS_COMPILE=aarch64-linux-gnu- PLAT=qemu DEBUG=1 BL33=$(UBOOT_SRC)/u-boot.bin all fip -j16 -C $(ATF_SRC)

$(UBOOT_SRC)/u-boot.bin: $(UBOOT_SRC)
	$(MAKE) qemu_arm64_defconfig -C $(UBOOT_SRC)
	$(MAKE) CROSS_COMPILE=aarch64-linux-gnu- -j16 -C $(UBOOT_SRC)

riscv:
	qemu-system-riscv64 $(QEMU_ARGS) \
	-initrd $(ROOTFS) \
	-kernel $(KBUILD_OUTPUT)/arch/riscv/boot/Image \
	-append "$(BOOT_ARGS)"

dtb: dts/qemu.dts
	cpp -nostdinc -undef -I./dts -D__DTS__ -x assembler-with-cpp -o qemu.dts.tmp $<
	dtc -I dts -O dtb -o qemu.dtb qemu.dts.tmp
	rm qemu.dts.tmp

dump_dts:
	qemu-system-aarch64 $(QEMU_ARGS) -machine dumpdtb=dump.dtb
	dtc -I dtb -O dts -o dump.dts dump.dtb
	rm dump.dtb

run_gdb:
	gnome-terminal -- gdb-multiarch --ix 'target remote :1234' $(KBUILD_OUTPUT)/vmlinux
