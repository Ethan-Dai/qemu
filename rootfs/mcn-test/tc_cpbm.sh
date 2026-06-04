#!/bin/sh

TEST_DESC="MPAM CMAX limit"
. $(dirname $0)/common.sh

echo 65535 > /sys/kernel/mcn/mpam/0/cmax
echo 0-7 > /sys/kernel/mcn/mpam/0/cpbm
cat /sys/kernel/mcn/mpam/0/cpbm

echo 0 > /sys/kernel/debug/mcn/slc_ctrl
cat /sys/kernel/debug/mcn/slc_ctrl
echo 3 > /sys/kernel/debug/mcn/slc_ctrl
cat /sys/kernel/debug/mcn/slc_ctrl

echo 0 > $DEBUGFS/mcn/csumon/csu
mem_wr
cat $DEBUGFS/mcn/csumon/csu
