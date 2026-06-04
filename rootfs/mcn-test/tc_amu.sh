#!/bin/sh

TEST_DESC="MCN AMU"
. $(dirname $0)/common.sh

cat $DEBUGFS/mcn/amu/counters

echo 0x3 > $DEBUGFS/mcn/amu/trace_en
cat $DEBUGFS/mcn/amu/trace_en

echo 1000000 > $DEBUGFS/mcn/amu/trace_period_us
cat $DEBUGFS/mcn/amu/trace_en

echo 1 > $TRACEFS/events/mcn/tracing_mark_write/enable
echo 1 > $TRACEFS/tracing_on
sleep 3
cat $TRACEFS/trace
