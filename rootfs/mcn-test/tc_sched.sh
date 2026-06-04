#!/bin/sh

TEST_DESC="MCN scheduler"
. $(dirname $0)/common.sh

file_write_check /sys/kernel/mcn/read_ot 255 255
file_write_check /sys/kernel/mcn/write_ot 255 255
file_write_check /sys/kernel/mcn/rwcomb_ot 255 255

file_write_check /sys/kernel/mcn/wpr_en 1 1

file_write_check /sys/kernel/mcn/zero_qos 1 1

PASS
