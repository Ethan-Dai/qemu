#!/bin/sh

qemu-system-aarch64 \
	-fsdev local,security_model=passthrough,id=fsdev0,path=share \
	-device virtio-9p-pci,fsdev=fsdev0,mount_tag=hostshare \
	-machine virt,virtualization=true,gic-version=3 \
	-nographic \
	-m size=512M \
	-cpu cortex-a57 \
	-smp 2 \
	-kernel Image \
	-initrd rootfs.cpio.gz \
	--append "console=ttyAMA0 rdinit=/linuxrc"
