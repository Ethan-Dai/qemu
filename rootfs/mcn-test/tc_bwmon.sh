#!/bin/sh

TEST_DESC="MPAM bandwidth monitor"
. $(dirname $0)/common.sh

echo P0RW,P1RW,P0RO,P0WO > $DEBUGFS/mcn/bwmon/bwmon
echo 0x3 > $DEBUGFS/mcn/bwmon/trace_en
cat $DEBUGFS/mcn/bwmon/trace_en

echo 1 > $TRACEFS/events/mcn/tracing_mark_write/enable
echo 1 > $TRACEFS/tracing_on

mem_wr

cat $DEBUGFS/mcn/bwmon/bwmon
cat $TRACEFS/trace
