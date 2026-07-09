#!/bin/sh

TEST_DESC="MPAM CMAX limit"
. $(dirname $0)/common.sh

echo 0-15 > /sys/kernel/mcn/mpam/0/cpbm
echo 32768 > /sys/kernel/mcn/mpam/0/cmax
cat /sys/kernel/mcn/mpam/0/cmax

echo 0 > ${DEBUGFS}mcn/slc_ctrl
cat ${DEBUGFS}mcn/slc_ctrl
echo 3 > ${DEBUGFS}mcn/slc_ctrl
cat ${DEBUGFS}mcn/slc_ctrl

echo 0,3,1,5 > $DEBUGFS/mcn/csumon/csu
mem_wr
cat $DEBUGFS/mcn/csumon/csu

echo 65535 > /sys/kernel/mcn/mpam/0/cmax

PASS
