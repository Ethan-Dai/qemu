#!/bin/sh

TEST_DESC="MCN RAS"
. $(dirname $0)/common.sh

echo 1 0x1ff > $DEBUGFS/mcn/err_inject

dmesg -c | grep RAS

PASS
