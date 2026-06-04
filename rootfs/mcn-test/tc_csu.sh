#!/bin/sh

TEST_DESC="MPAM CSU"
. $(dirname $0)/common.sh

echo 0,3,1,5 > $DEBUGFS/mcn/csumon/csu
cat $DEBUGFS/mcn/csumon/csu

PASS
