#!/bin/sh

TEST_DESC="MRL ways switch testing"
. $(dirname $0)/common.sh

MRL_WAYS=$DEBUGFS/mcn/mrl_ways
VALUES="0 1 2 4 6 8 12"
LOOP_CNT=${1:-1}
i=0

test_once()
{
	/lmbench/bw_mem -N 2 -P 7 64M wr &
	BGPID=$!

	set -- $VALUES
	while [ -d /proc/$BGPID ]; do
		rnd=$(od -An -N1 -tu1 /dev/urandom | tr -d ' ')
		idx=$((rnd % $# + 1))
		eval "val=\${$idx}"
		echo $val > $MRL_WAYS
	done

}

while [ $LOOP_CNT -eq 0 ] || [ $i -lt $LOOP_CNT ]; do
	[ $LOOP_CNT -ne 0 ] && i=$((i + 1))
	INFO "iteration $i"
	test_once
done

PASS
