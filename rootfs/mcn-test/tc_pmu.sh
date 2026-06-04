#!/bin/sh

TEST_DESC="MCN PMU test"
. $(dirname $0)/common.sh

perf stat -e {mcn/cycles/,mcn/slc_hit/,mcn/slc_miss/} sleep 1
dmesg -c | grep PMU

perf stat -e {mcn/r15b/,mcn/r1015b/,mcn/r1115b/} sleep 1
dmesg -c | grep PMU
