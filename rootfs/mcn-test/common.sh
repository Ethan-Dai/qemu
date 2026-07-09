#!/bin/sh

TEST_NAME=$(basename $0 .sh)
echo ""
echo ">>>>case $TEST_NAME start ..."
echo "  $TEST_DESC"

DEBUGFS=/sys/kernel/debug/
TRACEFS=/sys/kernel/tracing/

PASS()
{
	echo "  $TEST_NAME [result]: PASS"
	echo "<<<<case $TEST_NAME finished"
	exit 0
}

FAIL()
{
	echo "  $TEST_NAME [result]: FAIL"
	echo "<<<<case $TEST_NAME finished"
	exit 69
}

SKIP()
{
	echo "  $TEST_NAME [result]: SKIP"
	echo "<<<<case $TEST_NAME finished"
	exit 69
}

INFO()
{
	echo "  $TEST_NAME [info]: $1"
}

mount_debugfs()
{
	if [ "$(ls $DEBUGFS)" = "" ]; then
		INFO "The debugfs has not been mounted"
		mount -t debugfs debugfs $DEBUGFS
	fi
	if [ "$(ls $DEBUGFS)" = "" ]; then
		INFO "Failed to mount debugfs"
		SKIP
	fi
}

mem_wr()
{
	/lmbench/bw_mem -N 2 64M wr
}

file_write_check()
{
	if [ ! -f $1 ]; then
		INFO "$1 does not exist"
		FAIL
	fi

	echo $2 > $1
	if [ $? -ne 0 ]; then
		INFO "write $1 failed"
		FAIL
	fi

	val=$(cat $1)
	if [ $? -ne 0 ]; then
		INFO "read $1 failed"
		FAIL
	fi

	if [ "$val" != "$3" ]; then
		INFO "Expected '$3' but actually '$val'"
		FAIL
	fi
}
